import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/parent_model.dart';
import '../../data/models/institution_model.dart';
import '../../core/services/supabase_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Institution selection for login ───

/// Holds the institution the parent selected on the auth screens.
/// Must be set BEFORE sign-in / sign-up / forgot-password so the
/// correct schema is used for all queries.
final selectedAuthInstitutionProvider = StateProvider<InstitutionModel?>((ref) => null);

/// Persisted schema string (saved to SharedPreferences on login)
const String _schemaKey = 'saved_schema';
const String _insIdKey = 'saved_ins_id';

/// Custom auth state for parent-based authentication
class ParentAuthState {
  final ParentModel? parent;
  final bool isAuthenticated;

  ParentAuthState({
    this.parent,
    this.isAuthenticated = false,
  });

  ParentAuthState copyWith({
    ParentModel? parent,
    bool? isAuthenticated,
  }) {
    return ParentAuthState(
      parent: parent ?? this.parent,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Provider for parent authentication state
final parentAuthStateProvider =
    StateNotifierProvider<ParentAuthNotifier, AsyncValue<ParentAuthState>>(
        (ref) {
  return ParentAuthNotifier(ref.watch(supabaseClientProvider));
});

/// Legacy auth state provider - kept for compatibility
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// Current logged-in parent provider
final currentParentProvider = Provider<ParentModel?>((ref) {
  final authState = ref.watch(parentAuthStateProvider);
  return authState.valueOrNull?.parent;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

class ParentAuthNotifier extends StateNotifier<AsyncValue<ParentAuthState>> {
  final SupabaseClient _client;
  static const String _parentIdKey = 'logged_in_parent_id';
  static const String _tokenKey = 'app_session_token';

  ParentAuthNotifier(this._client)
      : super(AsyncValue.data(ParentAuthState())) {
    _loadSavedSession();
  }

  /// Load saved parent session from SharedPreferences.
  /// Restores both the schema and parent record.
  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedParentId = prefs.getInt(_parentIdKey);
      final savedSchema = prefs.getString(_schemaKey);
      final savedInsId = prefs.getInt(_insIdKey);

      // Restore the parent session token so RLS-scoped queries carry identity.
      final savedToken = prefs.getString(_tokenKey);
      if (savedToken != null && savedToken.isNotEmpty) {
        SupabaseService.sessionToken = savedToken;
      }

      if (savedParentId != null) {
        // Restore schema first so queries hit the right tables
        if (savedSchema != null && savedSchema.isNotEmpty) {
          SupabaseService.setSchema(savedSchema);
        } else if (savedInsId != null) {
          // Fallback: re-derive schema from institution
          await SupabaseService.determineAndSetSchema(savedInsId);
        }

        // Fetch parent from schema-specific parents table
        final response = await SupabaseService.fromSchema('parents')
            .select()
            .eq('par_id', savedParentId)
            .eq('activestatus', 1)
            .maybeSingle();

        if (response != null) {
          final parent = ParentModel.fromJson(response);
          state = AsyncValue.data(ParentAuthState(
            parent: parent,
            isAuthenticated: true,
          ));

          // Re-scan all institutions for this parent's mobile so newly-added
          // institutions appear without requiring logout/login.
          if (parent.payinchargemob.isNotEmpty) {
            unawaited(SupabaseService.findParentInstitutions(parent.payinchargemob).then((matches) {
              if (matches.isNotEmpty) {
                SupabaseService.setParentSchemas(matches);
                // Keep the previously active schema (don't override student context)
                if (savedSchema != null && savedSchema.isNotEmpty) {
                  SupabaseService.setSchema(savedSchema);
                }
              }
            }));
          }
        }
      }
    } catch (e) {
      // Silently fail - user will just need to login again
    }
  }

  /// Save parent session + schema to SharedPreferences
  Future<void> _saveSession(int parentId, int insId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_parentIdKey, parentId);
    await prefs.setInt(_insIdKey, insId);
    final schema = SupabaseService.currentSchema;
    if (schema != null) {
      await prefs.setString(_schemaKey, schema);
    }
  }

  /// Clear saved session and schema
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Revoke the server-side session so the token can't be reused after logout.
    final token = SupabaseService.sessionToken ?? prefs.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      try {
        await _client.rpc('revoke_session', params: {'p_token': token});
      } catch (_) {
        // Non-fatal — the token still expires server-side.
      }
    }
    SupabaseService.sessionToken = null;

    await prefs.remove(_parentIdKey);
    await prefs.remove(_insIdKey);
    await prefs.remove(_schemaKey);
    await prefs.remove(_tokenKey);
    SupabaseService.clearSchema();
  }

  /// Mint a server-side parent session token via `create_parent_session`
  /// (re-verifies parpassword) and hold + persist it. Sent as `x-app-token`
  /// on every request so RLS scopes data to this parent's students.
  Future<void> _mintParentToken(String mobile, String password, int insId) async {
    try {
      final token = await _client.rpc('create_parent_session', params: {
        'p_mobile': mobile,
        'p_plain_password': password,
        'p_ins_id': insId,
      });
      final t = token?.toString();
      if (t != null && t.isNotEmpty) {
        SupabaseService.sessionToken = t;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, t);
      }
    } catch (e) {
      // Non-fatal: RLS dual-mode isn't enforced until the parent policies land.
      debugPrint('create_parent_session failed (non-fatal): $e');
    }
  }

  /// Sign in using parent table - checks payinchargemob and parpassword.
  /// Schema must already be set via [SupabaseService.determineAndSetSchema]
  /// BEFORE calling this method (the sign-in screen handles that).
  Future<ParentModel> signIn({
    required String mobile,
    required String password,
    required int insId,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Clean mobile number - remove any non-digit characters
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Query parents table in institution schema
      final rows = await SupabaseService.fromSchema('parents')
          .select()
          .eq('payinchargemob', cleanMobile)
          .eq('activestatus', 1)
          .limit(1);

      if (rows.isEmpty) {
        throw Exception('Mobile number not registered');
      }

      final parent = ParentModel.fromJson(rows.first);

      // Check if account creation is complete (password is set)
      if (parent.parpassword == null || parent.parpassword!.isEmpty) {
        throw Exception(
            'Account setup incomplete. Please create your account first.');
      }

      // Verify password using pgcrypto's verify_password function
      final verifyResult = await _client.rpc('verify_password', params: {
        'plain_password': password,
        'hashed_password': parent.parpassword,
      });

      // RPC can return bool, String, or other formats - handle all cases
      final isValid = verifyResult == true ||
                      verifyResult == 'true' ||
                      verifyResult == 't' ||
                      verifyResult.toString() == 'true';

      if (!isValid) {
        throw Exception('Invalid password');
      }

      // Mint a server-side parent session token (re-verifies parpassword) so
      // RLS can scope reads/writes to this parent's students. Best-effort —
      // login still succeeds if it fails (RLS dual-mode not enforced yet).
      await _mintParentToken(cleanMobile, password, insId);

      // Save session with institution context
      await _saveSession(parent.parId, insId);

      state = AsyncValue.data(ParentAuthState(
        parent: parent,
        isAuthenticated: true,
      ));

      return parent;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Set authenticated session directly (used by the auto-detect sign-in and
  /// after account creation). When [mobile] + [plainPassword] are supplied, a
  /// server-side parent token is minted so RLS can scope this parent's data.
  Future<void> setAuthenticatedSession({
    required ParentModel parent,
    required int insId,
    String? mobile,
    String? plainPassword,
  }) async {
    // If the caller already minted a token (e.g. create_parent_session during
    // login), persist it; otherwise mint one now from the supplied credentials.
    if (SupabaseService.sessionToken != null &&
        SupabaseService.sessionToken!.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, SupabaseService.sessionToken!);
    } else if (mobile != null &&
        mobile.isNotEmpty &&
        plainPassword != null &&
        plainPassword.isNotEmpty) {
      await _mintParentToken(mobile, plainPassword, insId);
    }
    await _saveSession(parent.parId, insId);
    state = AsyncValue.data(ParentAuthState(
      parent: parent,
      isAuthenticated: true,
    ));
  }

  /// Sign out - clear parent session and schema
  Future<void> signOut() async {
    await _clearSession();
    state = AsyncValue.data(ParentAuthState());
  }

  /// Check if parent is authenticated
  bool get isAuthenticated => state.valueOrNull?.isAuthenticated ?? false;

  /// Get current parent
  ParentModel? get currentParent => state.valueOrNull?.parent;
}

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _client;
  final Ref _ref;

  AuthNotifier(this._client, this._ref) : super(const AsyncValue.data(null));

  /// The server's proof that this phone confirmed the OTP. Setting the password
  /// spends it.
  String? _otpTicket;

  /// The server creates the OTP and sends the SMS; the phone never sees either.
  Future<void> _sendOtp(String cleanMobile, {required String notFound}) async {
    final res = await _client.functions.invoke('parent-otp', body: {'mobile': cleanMobile});
    final data = res.data;
    final status = data is Map ? data['status']?.toString() : null;
    switch (status) {
      case 'SENT':
        _otpTicket = null;
        return;
      case 'NOT_FOUND':
        throw Exception(notFound);
      case 'WAIT':
        throw Exception('Please wait ${data['wait_seconds']} seconds before asking for a new OTP.');
      case 'LIMIT':
        throw Exception('Too many OTP requests. Please try again after an hour.');
      default:
        throw Exception('Failed to send OTP. Please try again.');
    }
  }

  /// Confirms the OTP with the server and keeps the ticket it returns.
  Future<void> _confirmOtp(String cleanMobile, String otp) async {
    final ticket = await _client.rpc('verify_parent_otp', params: {
      'p_mobile': cleanMobile,
      'p_otp': otp,
    });
    if (ticket == null || ticket.toString().isEmpty) {
      throw Exception('Invalid or expired OTP');
    }
    _otpTicket = ticket.toString();
  }

  /// Sets the password at every school this mobile is registered with.
  Future<bool> _savePassword(String cleanMobile, String password) async {
    final ticket = _otpTicket;
    if (ticket == null) return false;
    final ok = await _client.rpc('set_parent_password', params: {
      'p_mobile': cleanMobile,
      'p_ticket': ticket,
      'p_new_password': password,
    });
    _otpTicket = null;
    return ok == true;
  }

  /// Validate if mobile number exists in parents table.
  /// Auto-detects institution schema from the mobile number.
  /// Returns the parent if found, throws exception if not found.
  Future<ParentModel> validateMobileNumber(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanMobile.isEmpty) {
      throw Exception('Invalid mobile number format');
    }

    print('validateMobileNumber: cleanMobile=$cleanMobile, currentSchema=${SupabaseService.currentSchema}');

    // Auto-detect institution if schema not already set
    if (SupabaseService.currentSchema == null) {
      final result = await SupabaseService.findParentInstitution(cleanMobile);
      print('validateMobileNumber: findParentInstitution result insId=${result.insId}, schema=${result.schema}');
      if (result.insId == null) {
        throw Exception('Mobile number not registered. Contact school admin.');
      }
    }

    print('validateMobileNumber: querying schema=${SupabaseService.currentSchema} parents table with payinchargemob=$cleanMobile');
    final rows = await SupabaseService.fromSchema('parents')
        .select()
        .eq('payinchargemob', cleanMobile)
        .limit(1);

    print('validateMobileNumber: rows found=${rows.length}');
    if (rows.isNotEmpty) {
      print('validateMobileNumber: first row=${rows.first}');
    }

    if (rows.isEmpty) {
      throw Exception('Mobile number not registered. Contact school admin.');
    }

    final parent = ParentModel.fromJson(rows.first);

    // Check if account is active
    if (parent.activestatus != 1) {
      if (parent.activestatus == 2) {
        throw Exception('Account suspended. Contact school admin.');
      } else if (parent.activestatus == 9) {
        throw Exception('Account terminated. Contact school admin.');
      }
      throw Exception('Account inactive. Contact school admin.');
    }

    // Check if already has password (account already created)
    if (parent.parpassword != null && parent.parpassword!.isNotEmpty) {
      throw Exception('Account already exists. Please sign in instead.');
    }

    return parent;
  }

  Future<void> requestOtp({
    required String mobile,
    String countryCode = '+91',
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Discover the parent's institution via RPC (works with parents RLS-locked).
      final matches = await SupabaseService.findParentInstitutions(cleanMobile);
      if (matches.isEmpty) {
        throw Exception('Mobile number not registered. Contact school admin.');
      }
      // Sign-up is only for accounts that don't have a password yet.
      if (matches.any((m) => m.hasPassword)) {
        throw Exception('Account already exists. Please sign in instead.');
      }

      await _sendOtp(cleanMobile, notFound: 'Mobile number not registered. Contact school admin.');

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> verifyOtp({required String mobile, required String otp}) async {
    state = const AsyncValue.loading();
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      await _confirmOtp(cleanMobile, otp);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Complete account creation by setting password
  /// This UPDATES the existing parent record, does NOT create new
  Future<void> completeAccountCreation({
    required String mobile,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      if (!await _savePassword(cleanMobile, password)) {
        throw Exception('Failed to create account. Please verify OTP again.');
      }

      // Auto-login through the standard sign-in path (mints the scoped token +
      // loads the parent; refreshes parentSchemas).
      await signIn(mobile: cleanMobile, password: password);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign in using parent table authentication.
  /// Auto-detects the institution schema from the mobile number.
  Future<void> signIn({
    required String mobile,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Auto-detect ALL institutions where this parent exists
      final matches = await SupabaseService.findParentInstitutions(cleanMobile);
      if (matches.isEmpty) {
        throw Exception('Mobile number not registered in any institution.');
      }

      // Cache all schemas for multi-institution student fetching
      SupabaseService.setParentSchemas(matches);

      final passwordMatches = matches.where((m) => m.hasPassword).toList();
      if (passwordMatches.isEmpty) {
        throw Exception('Account setup incomplete. Please create your account first.');
      }

      // Verify the password SERVER-SIDE by minting a session token:
      // create_parent_session re-verifies parpassword and returns a token, so the
      // client never reads parpassword — this works with `parents` RLS-locked.
      // A parent may have different passwords per school; try each schema that has
      // a password and accept the first that authenticates.
      String? token;
      int? authInsId;
      String? authSchema;
      for (final m in passwordMatches) {
        try {
          final t = await _client.rpc('create_parent_session', params: {
            'p_mobile': cleanMobile,
            'p_plain_password': password,
            'p_ins_id': m.insId,
          });
          if (t != null && t.toString().isNotEmpty) {
            token = t.toString();
            authInsId = m.insId;
            authSchema = m.schema;
            break;
          }
        } catch (_) {
          // create_parent_session raises 'Invalid credentials' on a wrong
          // password — keep trying the parent's other schools.
        }
      }

      if (token == null || authInsId == null || authSchema == null) {
        throw Exception('Invalid password');
      }

      // Hold the token + active schema, then read the parent (now visible via the
      // parent-scoped RLS policy, keyed off the token's mobile).
      SupabaseService.sessionToken = token;
      SupabaseService.setActiveInstitution(authInsId, authSchema);

      final rows = await SupabaseService.fromSchema('parents')
          .select()
          .eq('payinchargemob', cleanMobile)
          .eq('activestatus', 1)
          .limit(1);
      if (rows.isEmpty) {
        throw Exception('Failed to load your account. Please try again.');
      }
      final parent = ParentModel.fromJson(rows.first);

      await _ref.read(parentAuthStateProvider.notifier).setAuthenticatedSession(
            parent: parent,
            insId: authInsId,
            mobile: cleanMobile,
            plainPassword: password,
          );
      state = const AsyncValue.data(null);
      return;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _ref.read(selectedAuthInstitutionProvider.notifier).state = null;
    await _ref.read(parentAuthStateProvider.notifier).signOut();
    await _client.auth.signOut();
  }

/// Request OTP for password reset (forgot password flow)
  /// This is different from requestOtp - it checks if account EXISTS
  Future<void> requestPasswordResetOtp({
    required String mobile,
    String countryCode = '+91',
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanMobile.isEmpty) {
        throw Exception('Invalid mobile number format');
      }

      final matches = await SupabaseService.findParentInstitutions(cleanMobile);
      if (matches.isEmpty) {
        throw Exception('Mobile number not registered. Please sign up first.');
      }
      // Reset is only for accounts that already have a password.
      if (!matches.any((m) => m.hasPassword)) {
        throw Exception('Account setup incomplete. Please complete sign up first.');
      }

      await _sendOtp(cleanMobile, notFound: 'Mobile number not registered. Please sign up first.');

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Verify OTP for password reset
  Future<void> verifyPasswordResetOtp({
    required String mobile,
    required String otp,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      await _confirmOtp(cleanMobile, otp);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Reset password for existing parent. Updates the password in EVERY
  /// schema where this mobile is registered so the new password works
  /// across all of the parent's institutions (matches the sign-up flow).
  Future<void> resetPassword({
    required String mobile,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      final matches = await SupabaseService.findParentInstitutions(cleanMobile);
      if (matches.isEmpty) {
        throw Exception('Mobile number not registered.');
      }
      if (!await _savePassword(cleanMobile, newPassword)) {
        throw Exception('Failed to reset password. Please verify OTP again.');
      }

      SupabaseService.setParentSchemas([
        for (final m in matches)
          (insId: m.insId, schema: m.schema, hasPassword: true)
      ]);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(supabaseClientProvider), ref);
});
