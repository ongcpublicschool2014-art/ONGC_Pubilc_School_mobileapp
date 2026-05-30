import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/parent_model.dart';
import '../../data/models/institution_model.dart';
import '../../core/services/sms_service.dart';
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
      // If the saved schema no longer exists in the current Supabase project
      // (e.g. the backend was migrated to a new project / rebranded), the
      // restore query fails with PGRST106 "Invalid schema". The stale schema
      // was already set globally above, so every later query would also fail
      // and surface error banners. Drop the stale session and reset to a clean
      // logged-out state so the user can simply log in again.
      if (e is PostgrestException &&
          (e.code == 'PGRST106' ||
              e.message.toLowerCase().contains('invalid schema'))) {
        await _clearSession();
        state = AsyncValue.data(ParentAuthState());
      }
      // Other errors: silently fail - user will just need to login again.
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
    await prefs.remove(_parentIdKey);
    await prefs.remove(_insIdKey);
    await prefs.remove(_schemaKey);
    SupabaseService.clearSchema();
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

  /// Set authenticated session directly (used after account creation)
  Future<void> setAuthenticatedSession({
    required ParentModel parent,
    required int insId,
  }) async {
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

      // Step 1: Validate mobile exists in parents table
      final parent = await validateMobileNumber(cleanMobile);

      // Step 2: Generate secure 6-digit OTP
      final otp = _generateSecureOtp();

      // Step 3: Store OTP in parent record (parmobotp field)
      await SupabaseService.fromSchema('parents').update({
        'parmobotp': int.parse(otp),
        'parotpstatus': 0, // Reset to pending
      }).eq('par_id', parent.parId);

      // Step 4: Send OTP via Twilio SMS
      final smsSent = await SmsService.sendOtp(
        phoneNumber: cleanMobile,
        otp: otp,
        countryCode: countryCode,
      );

      if (!smsSent) {
        throw Exception('Failed to send OTP. Please try again.');
      }

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

      // Query parent record with matching mobile and OTP
      final rows = await SupabaseService.fromSchema('parents')
          .select()
          .eq('payinchargemob', cleanMobile)
          .eq('parmobotp', int.parse(otp))
          .eq('parotpstatus', 0) // Not yet verified
          .eq('activestatus', 1)
          .limit(1);

      if (rows.isEmpty) {
        throw Exception('Invalid or expired OTP');
      }

      final response = rows.first;

      // Mark OTP as verified in parent record
      await SupabaseService.fromSchema('parents')
          .update({'parotpstatus': 1})
          .eq('par_id', response['par_id']);

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

      // Verify OTP was verified for this mobile
      final rows = await SupabaseService.fromSchema('parents')
          .select()
          .eq('payinchargemob', cleanMobile)
          .eq('parotpstatus', 1) // Must be verified
          .eq('activestatus', 1)
          .limit(1);

      if (rows.isEmpty) {
        throw Exception('Please verify OTP first');
      }

      final parent = ParentModel.fromJson(rows.first);

      // Update parent record with password and verify update succeeded
      final updateRows = await SupabaseService.fromSchema('parents').update({
        'parpassword': password,
        // Clear OTP after successful password set
        'parmobotp': null,
      }).eq('par_id', parent.parId).select().limit(1);

      if (updateRows.isEmpty) {
        throw Exception('Failed to create account. Please try again.');
      }

      // Auto-login: set session directly instead of going through signIn
      // (signIn uses verify_password RPC which may not work immediately
      //  if the DB hashes the password via a trigger)
      final updatedParent = ParentModel.fromJson(updateRows.first);
      await _ref.read(parentAuthStateProvider.notifier).setAuthenticatedSession(
            parent: updatedParent,
            insId: SupabaseService.currentInsId!,
          );

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

      // Prefer a schema where password is already set for authentication.
      // If no school has a password, require sign-up first.
      final authMatch = matches.firstWhere(
        (m) => m.hasPassword,
        orElse: () => (insId: -1, schema: '', hasPassword: false),
      );
      if (authMatch.insId == -1) {
        throw Exception('Account setup incomplete. Please create your account first.');
      }

      // Ensure the active schema is the one we're authenticating against
      SupabaseService.setSchema(authMatch.schema);

      await _ref.read(parentAuthStateProvider.notifier).signIn(
            mobile: mobile,
            password: password,
            insId: authMatch.insId,
          );
      state = const AsyncValue.data(null);
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

      // Auto-detect institution if schema not already set
      if (SupabaseService.currentSchema == null) {
        final result = await SupabaseService.findParentInstitution(cleanMobile);
        if (result.insId == null) {
          throw Exception('Mobile number not registered. Please sign up first.');
        }
      }

      // Check if account exists with password set
      final rows = await SupabaseService.fromSchema('parents')
          .select()
          .eq('payinchargemob', cleanMobile)
          .limit(1);

      if (rows.isEmpty) {
        throw Exception('Mobile number not registered. Please sign up first.');
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

      // Check if account has password (must exist for reset)
      if (parent.parpassword == null || parent.parpassword!.isEmpty) {
        throw Exception('Account setup incomplete. Please complete sign up first.');
      }

      // Generate secure 6-digit OTP
      final otp = _generateSecureOtp();

      // Store OTP in parent record
      await SupabaseService.fromSchema('parents').update({
        'parmobotp': int.parse(otp),
        'parotpstatus': 0, // Reset to pending
      }).eq('par_id', parent.parId);

      // Send OTP via SMS
      final smsSent = await SmsService.sendOtp(
        phoneNumber: cleanMobile,
        otp: otp,
        countryCode: countryCode,
      );

      if (!smsSent) {
        throw Exception('Failed to send OTP. Please try again.');
      }

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

      // Query parent record with matching mobile and OTP
      final rows = await SupabaseService.fromSchema('parents')
          .select()
          .eq('payinchargemob', cleanMobile)
          .eq('parmobotp', int.parse(otp))
          .eq('parotpstatus', 0) // Not yet verified
          .eq('activestatus', 1)
          .limit(1);

      if (rows.isEmpty) {
        throw Exception('Invalid or expired OTP');
      }

      final response = rows.first;

      // Mark OTP as verified
      await SupabaseService.fromSchema('parents')
          .update({'parotpstatus': 1})
          .eq('par_id', response['par_id']);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Reset password for existing parent
  Future<void> resetPassword({
    required String mobile,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Clean mobile number
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Verify OTP was verified for this mobile
      final verifyRows = await SupabaseService.fromSchema('parents')
          .select()
          .eq('payinchargemob', cleanMobile)
          .eq('parotpstatus', 1) // Must be verified
          .eq('activestatus', 1)
          .limit(1);

      if (verifyRows.isEmpty) {
        throw Exception('Please verify OTP first');
      }

      final verifyResponse = verifyRows.first;

      // Update password in parents table using par_id
      final updateRows = await SupabaseService.fromSchema('parents')
          .update({
            'parpassword': newPassword,
            'parmobotp': null, // Clear OTP after password reset
          })
          .eq('par_id', verifyResponse['par_id'])
          .select()
          .limit(1);

      if (updateRows.isEmpty) {
        throw Exception('Failed to reset password');
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Generate cryptographically secure 6-digit OTP
  String _generateSecureOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(supabaseClientProvider), ref);
});
