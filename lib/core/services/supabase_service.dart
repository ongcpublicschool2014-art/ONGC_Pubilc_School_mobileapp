import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase service with schema-based multi-tenancy support.
///
/// Tables in the PUBLIC schema (shared across institutions):
///   institution, institutionyear, year, country, state, city, currency, paymentgateway
///
/// Tables in INSTITUTION-SPECIFIC schemas (e.g. kcet20262027):
///   students, parents, parentdetail, feedemand, feetype, feegroup,
///   payment, paymentdetails, shoppingcart, shoppingcartdetails,
///   notification, concessioncategory, classfeedemand
class SupabaseService {
  /// Which of a student's outstanding demands may be paid right now.
  ///
  /// Returns dem_id -> {payable, partial_allowed, blocked_by}. The ordering
  /// (bus first, exam last, arrears before current year) is configured per fee
  /// type in the admin app and computed by the database, NOT by matching fee
  /// names here -- the cart, the counter and the payment RPC all ask the same
  /// function so they cannot disagree about what is allowed.
  ///
  /// Fails open: on any error every demand comes back payable, so a hiccup in
  /// this check can never stop a parent paying.
  static Future<Map<String, Map<String, dynamic>>> checkFeePaymentOrder(
      int insId, int stuId) async {
    try {
      final res = await client.rpc('check_fee_payment_order',
          params: {'p_ins_id': insId, 'p_stu_id': stuId});
      final list = res is List
          ? res
          : (res is String && res.isNotEmpty ? jsonDecode(res) as List : const []);
      return {
        for (final r in List<Map<String, dynamic>>.from(list))
          r['dem_id'].toString(): r,
      };
    } catch (e) {
      debugPrint('check_fee_payment_order unavailable: $e');
      return const {};
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Current institution schema name (e.g. 'kcet20262027')
  static String? _currentSchema;
  static String? get currentSchema => _currentSchema;

  /// Current institution ID (set alongside schema)
  static int? _currentInsId;
  static int? get currentInsId => _currentInsId;

  /// Server-issued parent session token. Sent as the `x-app-token` header on
  /// every request (see AppTokenHttpClient) so RLS can scope reads/writes to
  /// this parent's students. Set by AuthProvider on login / session restore.
  static String? sessionToken;

  /// Set the schema after login / institution selection
  static void setSchema(String? schema) {
    _currentSchema = schema;
    debugPrint('SupabaseService schema set to: $schema');
  }

  /// Set the active institution + schema together (used after login/OTP picks
  /// the authenticated schema so currentInsId matches currentSchema).
  static void setActiveInstitution(int insId, String schema) {
    _currentInsId = insId;
    _currentSchema = schema;
    debugPrint('SupabaseService active institution: ins_id=$insId schema=$schema');
  }

  /// Query from institution-specific schema table.
  /// Falls back to public if no schema is set, but logs a loud warning so
  /// schema-not-set bugs surface during development instead of silently
  /// reading/writing the wrong schema.
  static SupabaseQueryBuilder fromSchema(String table) {
    // School: fee types and fee groups are PUBLIC tables shared by every
    // academic year (scoped by ins_id), not per-year tables as on college.
    if (publicTables.contains(table)) return client.from(table);
    if (_currentSchema != null && _currentSchema!.isNotEmpty) {
      return client.schema(_currentSchema!).from(table);
    }
    debugPrint(
      '⚠️  fromSchema("$table") called with NO schema set — falling back to public. '
      'This usually means a query ran before login/student selection completed.',
    );
    return client.from(table);
  }

  /// Tables that live in the PUBLIC schema on the school database.
  static const Set<String> publicTables = {'feetype', 'feegroup'};

  /// Limits a public-table query to the current institution (when known).
  static PostgrestFilterBuilder<T> forIns<T>(PostgrestFilterBuilder<T> q) =>
      _currentInsId == null ? q : q.eq('ins_id', _currentInsId!);

  /// Adds each fee demand's fee type (with its fee group nested under
  /// `feegroup`) as `feetype` -- the shape FeeModel.fromJson reads.
  ///
  /// The database cannot embed it on school (feedemand is in the year schema,
  /// feetype in public), so it is joined here: by fee_id, else by fee type
  /// name. Never throws -- on any error the rows come back unchanged.
  static Future<List<Map<String, dynamic>>> withFeeTypes(dynamic rows) async {
    final list = <Map<String, dynamic>>[
      for (final r in (rows as List? ?? const []))
        if (r is Map) Map<String, dynamic>.from(r),
    ];
    if (list.isEmpty) return list;
    try {
      final insId = _currentInsId ?? (list.first['ins_id'] as num?)?.toInt();
      final query = client.from('feetype').select('*, feegroup(*)');
      final types = insId == null ? await query : await query.eq('ins_id', insId);
      final byId = <int, Map<String, dynamic>>{};
      final byName = <String, Map<String, dynamic>>{};
      for (final t in (types as List)) {
        final m = Map<String, dynamic>.from(t as Map);
        final id = (m['fee_id'] as num?)?.toInt();
        if (id != null) byId[id] = m;
        final name = (m['feedesc']?.toString() ?? '').trim().toUpperCase();
        if (name.isEmpty) continue;
        // Prefer an active fee type when two share a name.
        if (!byName.containsKey(name) || m['activestatus'] == 1) byName[name] = m;
      }
      for (final r in list) {
        if (r['feetype'] is Map) continue;
        final id = (r['fee_id'] as num?)?.toInt();
        final name = (r['demfeetype']?.toString() ?? '').trim().toUpperCase();
        final ft = (id != null ? byId[id] : null) ?? byName[name];
        if (ft != null) r['feetype'] = ft;
      }
    } catch (e) {
      debugPrint('withFeeTypes failed: $e');
    }
    return list;
  }

  /// The paying institution's own Paytm merchant, from the routing table
  /// `public.paytm_configuration` (institution_id -> merchant_id, is_active).
  /// The order is created under this MID so funds settle to that unit's own
  /// bank account.
  ///
  /// Only merchant_id is read. The table's website / industry_type / channel_id
  /// columns are NOT used — website comes from the edge function's
  /// PAYTM_WEBSITE env and channelId from this app's request — so changing them
  /// here has no effect.
  ///
  /// Returns null when no active row exists. Callers must NOT treat that as
  /// "use the default": see [resolvePaytmRouting], which refuses the payment.
  ///
  /// `paytm_configuration` lives in the PUBLIC schema (shared across units), so
  /// this uses the default client, not `fromSchema`.
  static Future<String?> getPaytmMidForInstitution(int insId) async {
    try {
      final row = await client
          .from('paytm_configuration')
          .select('merchant_id')
          .eq('institution_id', insId)
          .eq('is_active', true)
          .maybeSingle();
      final mid = row?['merchant_id']?.toString();
      return (mid != null && mid.isNotEmpty) ? mid : null;
    } catch (e) {
      debugPrint('getPaytmMidForInstitution error: $e');
      return null;
    }
  }

  /// Settings keys for a fee group's own receipt letterhead. Spelled exactly
  /// as the admin app spells them (SupabaseService.letterheadNameKey etc.) --
  /// the admin's Utilities screen WRITES these rows and this app READS them,
  /// so a difference of one character means the parent's receipt silently
  /// disagrees with the one printed at the counter.
  static String letterheadNameKey(int fgId) => 'letterhead_name_$fgId';
  static String letterheadAddrKey(int fgId) => 'letterhead_addr_$fgId';
  static String letterheadBannerKey(int fgId) => 'letterhead_banner_$fgId';

  /// Every institution_settings row for [insId], as a plain map.
  ///
  /// `institution_settings` lives in the PUBLIC schema, so this uses the
  /// default client rather than `fromSchema`.
  static Future<Map<String, String>> getInstitutionSettings(int insId) async {
    final out = <String, String>{};
    try {
      final rows = await client
          .from('institution_settings')
          .select('setting_key, setting_value')
          .eq('ins_id', insId);
      for (final r in (rows as List)) {
        final k = r['setting_key']?.toString();
        if (k == null || k.isEmpty) continue;
        out[k] = r['setting_value']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('getInstitutionSettings failed: $e');
    }
    return out;
  }

  /// The letterhead a receipt of [fgId] prints, falling back to the
  /// institution's own name and address. Mirrors the admin app's
  /// `letterheadFor` so both print the same header for the same receipt.
  static ({String name, String address, String banner}) letterheadFor({
    required int? fgId,
    required Map<String, String> settings,
    required String fallbackName,
    required String fallbackAddress,
  }) {
    if (fgId == null) {
      return (name: fallbackName, address: fallbackAddress, banner: '');
    }
    final n = (settings[letterheadNameKey(fgId)] ?? '').trim();
    final a = (settings[letterheadAddrKey(fgId)] ?? '').trim();
    final b = (settings[letterheadBannerKey(fgId)] ?? '').trim();
    return (
      name: n.isEmpty ? fallbackName : n,
      address: a.isEmpty ? fallbackAddress : a,
      banner: b,
    );
  }

  /// The letterhead for a receipt, resolved from the receipt's OWN fee types.
  ///
  /// One call for both the on-screen preview and the PDF, so they cannot print
  /// different headers for the same receipt.
  static Future<({String name, String address, String banner})>
      receiptLetterhead({
    required int insId,
    required List<String> feeTypes,
    required String fallbackName,
    required String fallbackAddress,
  }) async {
    final fgId = await feeGroupOfFeeTypes(feeTypes);
    final settings = await getInstitutionSettings(insId);
    return letterheadFor(
      fgId: fgId,
      settings: settings,
      fallbackName: fallbackName,
      fallbackAddress: fallbackAddress,
    );
  }

  /// The fee group a receipt's own fee types belong to -- the lowest fg_id
  /// among them, the same one save_misc_collection and the payment RPCs bank
  /// the receipt under.
  ///
  /// Resolved from the RECEIPT's lines, never from whatever the screen last
  /// had selected: screen state is reset before the receipt renders, which is
  /// how a hostel receipt ends up printing the college letterhead.
  static Future<int?> feeGroupOfFeeTypes(List<String> feeTypes) async {
    final wanted = feeTypes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (wanted.isEmpty) return null;
    try {
      final row = await forIns(fromSchema('feetype')
          .select('fg_id'))
          .inFilter('feedesc', wanted)
          .eq('activestatus', 1)
          .order('fg_id', ascending: true)
          .limit(1)
          .maybeSingle();
      return row?['fg_id'] as int?;
    } catch (e) {
      debugPrint('feeGroupOfFeeTypes failed: $e');
      return null;
    }
  }

  /// The fee groups a set of demands belongs to, with each group's name,
  /// beneficiary bank, and any demand whose group could NOT be worked out.
  ///
  /// The parent app pays a cart, and a cart may hold dues from more than one
  /// group -- college fees and a hostel mess fee. One Paytm order settles to
  /// ONE merchant, so the caller has to know whether this cart is a single
  /// group before it creates one.
  ///
  /// Three ways to reach the group, in the order the admin app and
  /// pendingFeesByGroupProvider already use them:
  ///
  ///   1. feedemand.fee_id  -> feetype.fg_id            (the reliable one)
  ///   2. feedemand.demfeetype matched to feetype.feedesc
  ///   3. demfeetype matched against the fee GROUP names
  ///
  /// It used to stop at (1). A demand with a null or dangling fee_id then fell
  /// out of the result entirely, and a cart holding one resolvable and one
  /// unresolvable due looked like a SINGLE group -- so the order was signed
  /// with the resolvable one's merchant while the server still raised a second
  /// receipt, banked somewhere else. Nothing on either receipt would show it.
  ///
  /// [unresolved] carries the dem_ids that still have no group after all
  /// three. It is deliberately not folded into the group map: the caller must
  /// decide, and refusing is the only safe answer -- a merchant guessed from
  /// the demands that DID resolve is a misroute waiting to happen.
  static Future<({
    Map<int, String> names,
    Map<int, int> banks,
    List<int> unresolved,
  })> feeGroupsForDemands(List<int> demIds) async {
    final names = <int, String>{};
    final banks = <int, int>{};
    final unresolved = <int>[];
    if (demIds.isEmpty) {
      return (names: names, banks: banks, unresolved: unresolved);
    }
    try {
      final dem = await fromSchema('feedemand')
          .select('dem_id, fee_id, demfeetype')
          .inFilter('dem_id', demIds);

      // Fee types and groups are small tables (dozens of rows), so one read of
      // each beats a round trip per demand -- and keeps every fallback below
      // working off the same snapshot.
      final types = await forIns(fromSchema('feetype')
          .select('fee_id, feedesc, fg_id'))
          .eq('activestatus', 1);
      final groups = await forIns(fromSchema('feegroup')
          .select('fg_id, fgdesc, ban_id'))
          .eq('activestatus', 1);

      final fgOfFeeId = <int, int>{};
      final fgOfFeeName = <String, int>{};
      for (final r in (types as List)) {
        final fg = r['fg_id'];
        if (fg is! int) continue;
        if (r['fee_id'] is int) fgOfFeeId[r['fee_id'] as int] = fg;
        final desc = (r['feedesc']?.toString() ?? '').trim().toUpperCase();
        if (desc.isNotEmpty) fgOfFeeName.putIfAbsent(desc, () => fg);
      }

      final groupName = <int, String>{};
      final groupBank = <int, int>{};
      for (final r in (groups as List)) {
        final fg = r['fg_id'];
        if (fg is! int) continue;
        groupName[fg] = (r['fgdesc']?.toString() ?? '').trim();
        if (r['ban_id'] is int) groupBank[fg] = r['ban_id'] as int;
      }

      for (final r in (dem as List)) {
        final demId = r['dem_id'];
        if (demId is! int) continue;
        final feeType = (r['demfeetype']?.toString() ?? '').trim().toUpperCase();

        int? fg;
        if (r['fee_id'] is int) fg = fgOfFeeId[r['fee_id'] as int];
        fg ??= feeType.isEmpty ? null : fgOfFeeName[feeType];
        if (fg == null && feeType.isNotEmpty) {
          // Last resort: the fee type reads like one of the group names
          // ("MESS FEE" against "HOSTEL FEES" will not match, which is the
          // point -- a wrong guess here is worse than admitting defeat).
          for (final e in groupName.entries) {
            final g = e.value.trim().toUpperCase();
            if (g.isEmpty) continue;
            if (feeType.contains(g) || g.contains(feeType)) {
              fg = e.key;
              break;
            }
          }
        }

        if (fg == null) {
          unresolved.add(demId);
          continue;
        }
        names[fg] = groupName[fg] ?? '';
        final ban = groupBank[fg];
        if (ban != null) banks[fg] = ban;
      }

      // A demand that came back from none of the three reads at all (deleted
      // between cart and checkout) is unresolved too -- not silently dropped.
      final seen = {
        for (final r in (dem as List))
          if (r['dem_id'] is int) r['dem_id'] as int,
      };
      for (final id in demIds) {
        if (!seen.contains(id) && !unresolved.contains(id)) unresolved.add(id);
      }
    } catch (e) {
      debugPrint('feeGroupsForDemands failed: $e');
      // Fail CLOSED. An empty result used to read as "one group, no bank",
      // which routes to the institution merchant -- the caller would pay
      // against a group it never actually identified.
      return (
        names: <int, String>{},
        banks: <int, int>{},
        unresolved: List<int>.from(demIds),
      );
    }
    return (names: names, banks: banks, unresolved: unresolved);
  }

  /// Which Paytm merchant an online payment is created under.
  ///
  /// Identical to the admin app's rule, deliberately: routing is per
  /// INSTITUTION, from public.paytm_configuration, and an unresolvable
  /// institution REFUSES the payment rather than falling back to the default
  /// parent merchant. That fallback is how money silently reached the parent
  /// account after a database rebuild — the app showed a normal receipt and
  /// Paytm showed every MID active, so nothing surfaced the misroute.
  /// Whether a payment settles to its FEE GROUP's own Paytm merchant.
  ///
  /// OFF until `FIX_PARENT_APP_BANK_ROUTING.sql` is deployed to production.
  /// The per-group lookup calls the `paytm_mid_for_routing` RPC, and this app
  /// REFUSES a payment it cannot route rather than guessing an account -- so
  /// shipping it before the SQL would stop every parent payment dead.
  ///
  /// While false, every payment is created under the institution's own
  /// merchant, exactly as the installed version does. Nothing regresses; the
  /// split simply does not happen yet.
  ///
  /// TO ENABLE: run the migration on live, then set the institution setting
  /// below -- shipping a new APK is no longer required.
  /// Nothing else needs changing -- the call sites already pass fgId/banId.
  static const bool kFeeGroupSettlement = false;

  /// The institution setting that turns the same routing on WITHOUT an APK:
  ///
  ///   INSERT INTO public.institution_settings
  ///       (ins_id, setting_key, setting_value, updatedat, updatedby)
  ///   VALUES (<ins>, 'fee_group_settlement', 'true', now(), 'ADMIN')
  ///   ON CONFLICT (ins_id, setting_key)
  ///   DO UPDATE SET setting_value = EXCLUDED.setting_value;
  ///
  /// This matters more here than on the desktop. A desktop build can be
  /// replaced the same afternoon; an APK cannot -- parents update when they
  /// feel like it, so a routing mistake shipped in an APK keeps mis-settling
  /// money on every phone that has not updated yet. A row flips for every
  /// phone at once, and flips back just as fast.
  static const String feeGroupSettlementKey = 'fee_group_settlement';

  /// Whether this payment should settle into its FEE GROUP's own merchant.
  ///
  /// True if EITHER the build opted in ([kFeeGroupSettlement], for a test
  /// build) OR the institution carries the setting. The compiled default stays
  /// false, so production can only reach it through a row anyone can see and
  /// reverse.
  ///
  /// A settings read that FAILS returns false: the institution's own merchant
  /// is what every installed version already uses, whereas assuming "on" would
  /// route live money on the strength of a failed lookup.
  /// ROUTING IS AUTOMATIC. A payment settles into its fee group's own merchant
  /// whenever that group is mapped to a bank and that bank names a Paytm
  /// merchant. Nothing has to be switched on.
  ///
  /// Safe because the FALLBACK is unchanged: a group with no bank, or a bank
  /// with no merchant, still resolves the institution's merchant, so a database
  /// with one fee group behaves exactly as it does today. Only a group naming a
  /// DIFFERENT account moves -- which is the case the mapping was created for.
  ///
  /// The setting is a KILL SWITCH, not an on-switch: `fee_group_settlement` set
  /// to 'false' forces every phone back through the institution's single
  /// merchant at once. On mobile that is the only fast undo there is, because
  /// an APK cannot be recalled -- parents update when they choose.
  static Future<bool> feeGroupSettlementEnabled(int insId) async {
    if (kFeeGroupSettlement) return true;
    try {
      final s = await getInstitutionSettings(insId);
      // Only an explicit 'false' disables it.
      return (s[feeGroupSettlementKey] ?? '').trim().toLowerCase() != 'false';
    } catch (e) {
      // A failed settings read says nothing about which account the money
      // belongs in, and an unmapped group still falls back to the
      // institution's merchant.
      debugPrint('feeGroupSettlementEnabled: $e');
      return true;
    }
  }

  static Future<PaytmRouting> resolvePaytmRouting({
    required int insId,
    int? fgId,
    int? banId,
  }) async {
    // The FEE GROUP's own merchant first. A hostel fee is banked into the
    // hostel account, so its order has to be signed with the hostel MERCHANT
    // -- signing it with the college one settles the money in the college
    // account and nothing on the receipt shows it.
    //
    // Asked through an RPC, NOT by selecting <schema>.bank. That table has RLS
    // on and its only read policy is
    //     (current_app_par() IS NULL) AND (ins_id = current_app_ins())
    // -- current_app_par() is the PARENT session marker, so in this app the
    // policy is false for every row and the select returned ZERO ROWS rather
    // than an error. The null read as "no merchant configured" and every
    // payment quietly fell back to the institution default, which is the
    // college one: hostel fees paid from a phone settled into the college
    // account. paytm_mid_for_routing is SECURITY DEFINER and returns the
    // merchant id alone, so the parent never needs to see the bank row.
    if ((fgId != null || banId != null) &&
        await feeGroupSettlementEnabled(insId)) {
      try {
        final mid = await client.rpc('paytm_mid_for_routing', params: {
          'p_ins_id': insId,
          'p_fg_id': fgId,
          'p_ban_id': banId,
        });
        final bankMid = mid?.toString().trim();
        if (bankMid != null && bankMid.isNotEmpty) {
          return PaytmRouting(
              mid: bankMid,
              source: fgId != null ? 'group:$fgId' : 'bank:$banId');
        }
        // Reached the lookup, got nothing back.
        return PaytmRouting(
            error: 'This fee group has no payment account set up yet '
                '(group $fgId). Please pay at the office, or contact support '
                'so it can be configured.');
      } catch (e) {
        debugPrint('resolvePaytmRouting group lookup failed: $e');
        return PaytmRouting(
            error: 'Could not confirm which account this payment settles to '
                '(group $fgId). Please try again, or pay at the office.');
      }
    }

    final String? insMid;
    try {
      insMid = await getPaytmMidForInstitution(insId);
    } catch (e) {
      debugPrint('resolvePaytmRouting lookup failed: $e');
      return const PaytmRouting(
          error: 'Could not work out which account this payment settles to. '
              'Please try again, or pay at the office.');
    }
    if (insMid == null) {
      return const PaytmRouting(
          error: 'Online payment is not set up for your institution yet. '
              'Please pay at the office, or contact support.');
    }
    return PaytmRouting(mid: insMid, source: 'institution');
  }

  /// Build schema name from institution short name and year label.
  /// e.g. ('kcet', '2026-2027') -> 'kcet20262027'
  static String buildSchemaName(String shortName, String yearLabel) {
    return '${shortName.toLowerCase()}${yearLabel.replaceAll('-', '')}';
  }

  /// Fetch the active academic year label for an institution.
  /// Tries `institutionyear` first, then `year`, then defaults to current year.
  static Future<String?> fetchActiveYearLabel(int insId) async {
    // 1. Try institutionyear table (primary source)
    try {
      final result = await client
          .from('institutionyear')
          .select('yrlabel')
          .eq('ins_id', insId)
          .eq('activestatus', 1)
          .order('iyr_id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (result != null && result['yrlabel'] != null) {
        return result['yrlabel'] as String;
      }
    } catch (e) {
      debugPrint('institutionyear query failed: $e');
    }

    // 2. Fallback to year table
    try {
      final result = await client
          .from('year')
          .select('yrlabel')
          .eq('ins_id', insId)
          .eq('activestatus', 1)
          .order('yr_id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (result != null && result['yrlabel'] != null) {
        return result['yrlabel'] as String;
      }
    } catch (_) {}

    // 3. Default to current academic year
    final now = DateTime.now();
    return '${now.year}-${now.year + 1}';
  }

  /// Determine and set the schema for a given institution ID.
  /// Returns the schema name on success, null on failure.
  static Future<String?> determineAndSetSchema(int insId) async {
    try {
      // Fetch institution short name
      final insRow = await client
          .from('institution')
          .select('inshortname')
          .eq('ins_id', insId)
          .maybeSingle();

      if (insRow == null || insRow['inshortname'] == null) {
        debugPrint('No institution found for ins_id=$insId');
        return null;
      }

      // Fetch active academic year (always returns a value with fallback)
      final yearLabel = await fetchActiveYearLabel(insId);
      if (yearLabel == null) {
        debugPrint('No year label for ins_id=$insId');
        return null;
      }

      final shortName = insRow['inshortname'] as String;
      final schema = buildSchemaName(shortName, yearLabel);
      _currentInsId = insId;
      setSchema(schema);
      return schema;
    } catch (e) {
      debugPrint('Error determining schema: $e');
      return null;
    }
  }

  /// Find ALL institutions where a parent exists (by mobile number).
  /// Returns list of (insId, schema, hasPassword) records.
  /// Active schema is set to the FIRST match that has a password already configured
  /// (falls back to first match overall if none have passwords yet).
  ///
  /// Searches every academic-year schema per institution (most recent first),
  /// not just the latest active year. The admin app's year-rollover doesn't
  /// copy parent records forward, so a parent's password may live in an older
  /// year's schema even after the institution promotes to a new year.
  static Future<List<({int insId, String schema, bool hasPassword})>> findParentInstitutions(String mobile) async {
    final matches = <({int insId, String schema, bool hasPassword})>[];

    try {
      // Best-effort: refresh PostgREST's db_schemas so every discovered schema is
      // queryable via client.schema(...). No-op when already current.
      try {
        await client.rpc('expose_all_schemas');
      } catch (e) {
        debugPrint('expose_all_schemas RPC skipped: $e');
      }

      // Discovery runs through a SECURITY DEFINER RPC (find_parent_institutions)
      // so it works even when `parents` is RLS-locked — there is no session token
      // yet at login time. The RPC scans every institution schema server-side and
      // returns ins_id / schema / has_password only (never the password hash).
      final rows = await client.rpc('find_parent_institutions', params: {'p_mobile': mobile});
      for (final r in (rows as List)) {
        final insId = (r['ins_id'] as num).toInt();
        final schema = r['schema'] as String;
        final hasPassword = r['has_password'] == true;
        debugPrint('find_parent_institutions: $schema (ins_id=$insId, hasPassword=$hasPassword)');
        matches.add((insId: insId, schema: schema, hasPassword: hasPassword));
      }

      // Prefer a schema where the password is already set (for login);
      // fall back to the first match (sign-up flow).
      if (matches.isNotEmpty) {
        final authMatch = matches.firstWhere(
          (m) => m.hasPassword,
          orElse: () => matches.first,
        );
        _currentInsId = authMatch.insId;
        setSchema(authMatch.schema);
      }
    } catch (e) {
      debugPrint('Error finding parent institutions: $e');
    }

    return matches;
  }

  /// Convenience wrapper — returns first match for backward compat.
  static Future<({int? insId, String? schema})> findParentInstitution(String mobile) async {
    final matches = await findParentInstitutions(mobile);
    if (matches.isEmpty) return (insId: null, schema: null);
    return (insId: matches.first.insId, schema: matches.first.schema);
  }

  /// Cached list of schemas where the current parent exists.
  /// Populated during login, used by studentsByParentProvider.
  static List<({int insId, String schema, bool hasPassword})> _parentSchemas = [];
  static List<({int insId, String schema, bool hasPassword})> get parentSchemas => _parentSchemas;

  static void setParentSchemas(List<({int insId, String schema, bool hasPassword})> schemas) {
    _parentSchemas = schemas;
  }

  /// Clear the current schema (on logout)
  static void clearSchema() {
    _currentSchema = null;
    _currentInsId = null;
    _parentSchemas = [];
    debugPrint('SupabaseService schema cleared');
  }
}

/// Outcome of [SupabaseService.resolvePaytmRouting] — which Paytm merchant an
/// online payment is created under, or why it must not be taken at all.
/// Mirrors the admin app's type of the same name so both flows stay in step.
class PaytmRouting {
  /// Merchant the order is created under; null when [error] is set.
  final String? mid;

  /// Non-null means do not take the payment — show this to the student.
  final String? error;

  /// Where [mid] came from, for the debug log.
  final String source;

  const PaytmRouting({this.mid, this.error, this.source = ''});

  bool get ok => error == null;
}
