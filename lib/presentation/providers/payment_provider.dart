import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fee_model.dart';
import '../../data/models/payment_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/paytm_service.dart';
import 'student_provider.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'fee_provider.dart';
import 'notification_provider.dart';

/// Fetch payments from Supabase 'payment' table (schema-specific)
final paymentsProvider = FutureProvider<List<PaymentModel>>((ref) async {
  final student = ref.watch(selectedStudentProvider);

  if (student == null) return [];

  try {
    final response = await SupabaseService.fromSchema('payment')
        .select('*')
        .eq('stu_id', student.stuId)
        .eq('activestatus', 1)
        .neq('paystatus', 'I')
        .order('createdat', ascending: false);

    return (response as List<dynamic>)
        .map((e) => PaymentModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching payments: $e');
    return [];
  }
});

/// Fetch payments by institution ID (schema-specific)
final paymentsByInstitutionProvider = FutureProvider.family<List<PaymentModel>, int>((ref, insId) async {
  try {
    final response = await SupabaseService.fromSchema('payment')
        .select('*')
        .eq('ins_id', insId)
        .eq('activestatus', 1)
        .order('createdat', ascending: false);

    return (response as List<dynamic>)
        .map((e) => PaymentModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching payments by institution: $e');
    return [];
  }
});

/// Fetch a single payment by ID
final paymentByIdProvider = FutureProvider.family<PaymentModel?, int>((ref, payId) async {
  try {
    final response = await SupabaseService.fromSchema('payment')
        .select('*')
        .eq('pay_id', payId)
        .maybeSingle();

    if (response != null) {
      return PaymentModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching payment by ID: $e');
    return null;
  }
});

/// Fetch fee details for a single payment (for receipt display)
final paymentFeeDetailsProvider = FutureProvider.family<List<FeeModel>, int>((ref, payId) async {
  try {
    // 1. Get payment details (links payment to feedemand records)
    final details = await SupabaseService.fromSchema('paymentdetails')
        .select('*')
        .eq('pay_id', payId)
        .eq('activestatus', 1);

    final detailModels = (details as List)
        .map((d) => PaymentDetailModel.fromJson(d))
        .toList();

    if (detailModels.isEmpty) return [];

    final demIds = detailModels.map((d) => d.demId).toList();

    // 2. Fetch feedemand records with fee type info
    List<FeeModel> feeModels;
    try {
      final fees = await SupabaseService.fromSchema('feedemand')
          .select('*')
          .inFilter('dem_id', demIds);
      feeModels = (await SupabaseService.withFeeTypes(fees)).map((f) => FeeModel.fromJson(f)).toList();
    } catch (e) {
      final fees = await SupabaseService.fromSchema('feedemand')
          .select('*')
          .inFilter('dem_id', demIds);
      feeModels = (await SupabaseService.withFeeTypes(fees)).map((f) => FeeModel.fromJson(f)).toList();
    }

    // 3. Map paid amounts from payment details
    final detailMap = <int, PaymentDetailModel>{};
    for (final d in detailModels) {
      detailMap[d.demId] = d;
    }

    return feeModels.map((fee) {
      final detail = detailMap[fee.demId];
      if (detail != null) {
        return fee.copyWith(paidamount: detail.transtotalamount);
      }
      return fee;
    }).toList();
  } catch (e) {
    debugPrint('Error fetching payment fee details: $e');
    return [];
  }
});

/// Recent payments (last 5)
final recentPaymentsProvider = Provider<List<PaymentModel>>((ref) {
  final paymentsAsync = ref.watch(paymentsProvider);
  return paymentsAsync.maybeWhen(
    data: (payments) => payments.take(5).toList(),
    orElse: () => [],
  );
});

/// Successful payments only
final successfulPaymentsProvider = Provider<List<PaymentModel>>((ref) {
  final paymentsAsync = ref.watch(paymentsProvider);
  return paymentsAsync.maybeWhen(
    data: (payments) => payments
        .where((p) => p.paystatus == 'C')
        .toList(),
    orElse: () => [],
  );
});

/// Shopping cart provider (schema-specific)
final shoppingCartProvider = FutureProvider.family<ShoppingCartModel?, int>((ref, carId) async {
  try {
    final response = await SupabaseService.fromSchema('shoppingcart')
        .select('*')
        .eq('car_id', carId)
        .maybeSingle();

    if (response != null) {
      return ShoppingCartModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching shopping cart: $e');
    return null;
  }
});

/// Shopping cart details provider (schema-specific)
final shoppingCartDetailsProvider = FutureProvider.family<List<ShoppingCartDetailModel>, int>((ref, carId) async {
  try {
    final response = await SupabaseService.fromSchema('shoppingcartdetails')
        .select('*')
        .eq('car_id', carId)
        .eq('activestatus', 1);

    return (response as List<dynamic>)
        .map((e) => ShoppingCartDetailModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching shopping cart details: $e');
    return [];
  }
});

/// Deletes the active cart from database for a student
Future<bool> clearCartFromDatabase({
  required WidgetRef ref,
  required int studentId,
}) async {
  try {
    // Find active cart for this student
    final existingCart = await SupabaseService.fromSchema('shoppingcart')
        .select('car_id')
        .eq('stu_id', studentId)
        .eq('carinitiated', 'N')
        .eq('activestatus', 1)
        .maybeSingle();

    if (existingCart != null) {
      final carId = existingCart['car_id'] as int;

      // Delete cart details first (foreign key constraint)
      await SupabaseService.fromSchema('shoppingcartdetails').delete().eq('car_id', carId);

      // Delete the cart
      await SupabaseService.fromSchema('shoppingcart').delete().eq('car_id', carId);

      debugPrint('Cart cleared from DB: car_id=$carId');

      // Check if table is empty and reset sequence
      final remainingCarts = await SupabaseService.fromSchema('shoppingcart')
          .select('car_id')
          .limit(1);

      if ((remainingCarts as List).isEmpty) {
        // Reset sequences when tables are empty
        await SupabaseService.client.rpc('reset_cart_sequences');
        debugPrint('Cart sequences reset to 1');
      }
    }
    return true;
  } catch (e) {
    debugPrint('Error clearing cart from database: $e');
    return false;
  }
}

/// Saves the in-memory cart to Supabase shoppingcart + shoppingcartdetails tables.
/// Returns the created car_id on success, or null on failure.
/// Error message from the last saveCartToDatabase call
String? lastCartSaveError;

Future<int?> saveCartToDatabase({
  required WidgetRef ref,
  required List<FeeModel> items,
  required int studentId,
}) async {
  lastCartSaveError = null;
  final student = ref.read(selectedStudentProvider);
  final parent = ref.read(currentParentProvider);
  if (student == null || items.isEmpty) return null;

  // Use yr_id/yrlabel from the first fee item
  final firstFee = items.first;
  final totalAmount = items.fold<double>(0, (sum, f) => sum + f.balancedue);

  // Arrear years aren't in the year master (yr_id <= 0) but shoppingcart.yr_id
  // is NOT NULL / FK — fall back to the current active year (matches the admin).
  int? cartFallbackYrId;
  if (items.any((f) => f.yrId <= 0)) {
    try {
      final r = await SupabaseService.fromSchema('year')
          .select('yr_id')
          .eq('activestatus', 1)
          .order('yr_id', ascending: false)
          .limit(1)
          .maybeSingle();
      cartFallbackYrId = (r?['yr_id'] as num?)?.toInt();
    } catch (_) {}
  }
  int effYr(int y) => (y > 0) ? y : (cartFallbackYrId ?? y);

  try {
    // Check if student already has active (non-finalized) carts
    final existingCarts = await SupabaseService.fromSchema('shoppingcart')
        .select('car_id, carinitiated')
        .eq('stu_id', student.stuId)
        .eq('activestatus', 1)
        .order('car_id', ascending: false);

    // Separate non-initiated carts from stale initiated carts
    final activeCarts = <Map<String, dynamic>>[];
    final staleCarts = <Map<String, dynamic>>[];
    for (final c in (existingCarts as List)) {
      if (c['carinitiated']?.toString().trim() == 'N') {
        activeCarts.add(c);
      } else if (c['carinitiated']?.toString().trim() == 'I') {
        staleCarts.add(c);
      }
    }

    debugPrint('Found ${existingCarts.length} carts, ${activeCarts.length} active, ${staleCarts.length} stale for student ${student.stuId}');

    // Clean up stale initiated carts (from failed/abandoned payments)
    for (final stale in staleCarts) {
      final staleCarId = stale['car_id'] as int;
      await SupabaseService.fromSchema('shoppingcartdetails').delete().eq('car_id', staleCarId);
      await SupabaseService.fromSchema('shoppingcart').delete().eq('car_id', staleCarId);
      debugPrint('Deleted stale initiated cart: $staleCarId');
    }

    int carId;

    if (activeCarts.isNotEmpty) {
      // Use the most recent cart
      carId = activeCarts.first['car_id'] as int;

      // Delete any other duplicate carts for this student
      for (int i = 1; i < activeCarts.length; i++) {
        final oldCarId = activeCarts[i]['car_id'] as int;
        await SupabaseService.fromSchema('shoppingcartdetails').delete().eq('car_id', oldCarId);
        await SupabaseService.fromSchema('shoppingcart').delete().eq('car_id', oldCarId);
        debugPrint('Deleted duplicate cart: $oldCarId');
      }

      // Update cart header with new total, date, and createdby
      await SupabaseService.fromSchema('shoppingcart').update({
        'yr_id': effYr(firstFee.yrId),
        'yrlabel': firstFee.demfeeyear,
        'transdate': DateTime.now().toIso8601String().split('T')[0],
        'transtotalamount': totalAmount,
        'createdby': parent?.payincharge ?? student.stuname,
      }).eq('car_id', carId);

      // Delete old cart details
      await SupabaseService.fromSchema('shoppingcartdetails')
          .delete()
          .eq('car_id', carId);
    } else {
      // Create new cart
      final cartResponse = await SupabaseService.fromSchema('shoppingcart').insert({
        'yr_id': effYr(firstFee.yrId),
        'yrlabel': firstFee.demfeeyear,
        'ins_id': student.insId,
        'stu_id': student.stuId,
        'transtype': 'FEE',
        'transdate': DateTime.now().toIso8601String().split('T')[0],
        'transcurrency': 'INR',
        'transtotalamount': totalAmount,
        'carinitiated': 'N',
        'createdby': parent?.payincharge ?? student.stuname,
      }).select('car_id').single();

      carId = cartResponse['car_id'] as int;
    }

    // Insert cart details
    final detailRows = items.map((fee) => {
      'car_id': carId,
      'yr_id': effYr(fee.yrId),
      'yrlabel': fee.demfeeyear,
      'ins_id': fee.insId,
      'dem_id': fee.demId,
      'transcurrency': 'INR',
      'transtotalamount': fee.balancedue,
    }).toList();

    await SupabaseService.fromSchema('shoppingcartdetails').insert(detailRows);

    debugPrint('Cart saved to DB: car_id=$carId, ${items.length} detail rows');
    return carId;
  } catch (e, stackTrace) {
    lastCartSaveError = e.toString();
    debugPrint('Error saving cart to database: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
}

/// Step 3: Initiate payment - creates payment + paymentdetails records.
/// Accepts cart data directly to avoid redundant DB fetches.
/// Returns pay_id on success, null on failure.
String? lastPaymentError;

/// [partMap] dem_id -> the amount to pay when it is LESS than that demand's
/// balance (a part payment). Absent means pay the whole balance. It travels the
/// same per-demand route as [fineMap] so the figure the parent approved is the
/// figure recorded against the demand -- deriving it again downstream is how
/// the two drift apart.
/// The amount to charge for one fee: the part amount when the parent chose
/// one, otherwise the full balance. Clamped to the balance so a stale or
/// tampered value can never collect more than is owed -- the server enforces
/// the same ceiling, this just keeps the app from ever asking.
double _payable(FeeModel fee, Map<int, double>? partMap) {
  final part = partMap?[fee.demId];
  if (part == null || part <= 0 || part >= fee.balancedue) return fee.balancedue;
  return part;
}

/// True when this demand is being PART paid.
bool _isPartPayment(FeeModel fee, Map<int, double>? partMap) =>
    _payable(fee, partMap) < fee.balancedue;

/// The fine to charge on this line.
///
/// ZERO on a part payment, deliberately. complete_payment_grouped applies the
/// whole `amount` against balancedue and never touches fineamount, so a line of
/// fee+fine reduces the FEE balance by the fine as well: pay 10,000 of a 70,000
/// balance carrying a 500 fine and the balance drops to 59,500 -- the student is
/// credited 500 of fee nobody paid, and still owes the 500 fine.
///
/// That fold-in is harmless when the demand is cleared in full (the reports
/// subtract fineamount to compensate) but not when a balance survives. Rather
/// than change complete_payment_grouped -- which the counter also uses -- a
/// part payment settles fee only and leaves the fine outstanding, to be paid
/// when the demand is cleared.
double _fineFor(FeeModel fee, Map<int, double>? fineMap, Map<int, double>? partMap) =>
    _isPartPayment(fee, partMap) ? 0 : (fineMap?[fee.demId] ?? 0);

Future<int?> initiatePayment({
  required WidgetRef ref,
  required int carId,
  required List<FeeModel> cartItems,
  required double cartTotal,
  Map<int, double>? fineMap,
  Map<int, double>? partMap,
}) async {
  lastPaymentError = null;

  final student = ref.read(selectedStudentProvider);
  final parent = ref.read(currentParentProvider);
  if (student == null || cartItems.isEmpty) return null;

  try {
    var items = cartItems;
    var totalAmount = cartTotal;

    // 0. Stale 'I' (initiated-but-abandoned) payments are cleaned up inside the
    //    create_pending_payment RPC (SECURITY DEFINER), so no direct delete here.

    // 1. Validate: check actual balancedue from DB to prevent double payment.
    //    Also pull fee_id here so the fee-group config check below reuses this
    //    single read instead of a second identical feedemand round-trip.
    final demIds = items.map((f) => f.demId).toList();
    final freshDemands = await SupabaseService.fromSchema('feedemand')
        .select('dem_id, balancedue, paidstatus, fee_id')
        .inFilter('dem_id', demIds);

    // Filter out already-paid fees (balancedue <= 0 or paidstatus = 'P')
    final paidDemIds = <int>{};
    for (final d in (freshDemands as List)) {
      final bal = (d['balancedue'] as num?)?.toDouble() ?? 0;
      if (bal <= 0 || d['paidstatus'] == 'P') {
        paidDemIds.add(d['dem_id'] as int);
      }
    }

    if (paidDemIds.isNotEmpty) {
      // Remove already-paid items
      items = items.where((f) => !paidDemIds.contains(f.demId)).toList();
      totalAmount = items.fold(0.0, (sum, f) => sum + f.balancedue);

      if (items.isEmpty) {
        lastPaymentError = 'All fees have already been paid';
        return null;
      }

      // Also update in-memory cart to remove paid items
      for (final demId in paidDemIds) {
        ref.read(cartProvider.notifier).removeFee(demId.toString());
      }

      debugPrint('Removed ${paidDemIds.length} already-paid fees from payment');
    }

    // 1b. ONE PAYMENT AT A TIME, ONCE IT HAS REACHED PAYTM.
    //
    // An 'I' row WITH a payorderid is a payment the gateway already knows
    // about: the order was signed and the checkout opened. Paytm can still
    // capture against it minutes later -- the parent completing the page they
    // left open, or a bank confirming late -- so a second attempt now is how a
    // family pays twice for one fee.
    //
    // check_fees_locked does not cover this. It fires only for the SAME
    // dem_ids and only for 15 minutes, so paying a DIFFERENT fee while one is
    // in flight walks straight past it, and so does anything older than a
    // quarter of an hour.
    //
    // THE ORDER ID IS THE TEST, not age and not the fee. An 'I' row without
    // one provably never reached the gateway, no money can exist against it,
    // and create_pending_payment clears those itself -- blocking on those
    // would stop parents paying for no reason at all.
    //
    // NOT A DEAD END. Paytm is asked first and is the authority:
    //   * it says the payment FAILED  -> the row is marked 'F' and this
    //                                    attempt carries on normally;
    //   * it says the payment WORKED  -> the receipt is raised from the row
    //                                    that already exists, and paying again
    //                                    is exactly what must not happen;
    //   * it has no verdict yet       -> blocked, and the parent is told to
    //                                    wait rather than left guessing.
    // So an abandoned checkout -- the common case, where the parent opened the
    // page and closed it -- clears itself on the next tap instead of locking
    // the family out of the app forever.
    try {
      final inFlight = await SupabaseService.fromSchema('payment')
          .select('pay_id, payorderid, transtotalamount, createdat')
          .eq('ins_id', student.insId)
          .eq('stu_id', student.stuId)
          .eq('paystatus', 'I')
          // Orders of the school's own gateways are settled by the server.
          .isFilter('pg_id', null)
          // NULL *and* empty both mean "never reached the gateway" -- the
          // rule the SQL side states explicitly as length(btrim(...)) = 0.
          // Without the second test a blank string reads as in-flight and
          // blocks a parent from paying for a payment that never started.
          .not('payorderid', 'is', null)
          .neq('payorderid', '')
          .order('createdat', ascending: false)
          .limit(1);

      if (inFlight.isNotEmpty) {
        final row = Map<String, dynamic>.from(inFlight.first);
        final stuckId = (row['pay_id'] as num).toInt();
        final stuckAmt = (row['transtotalamount'] as num?)?.toDouble() ?? 0;
        final startedAt = DateTime.tryParse(row['createdat']?.toString() ?? '');
        final stuckAge = startedAt == null
            ? const Duration(days: 365)
            : DateTime.now().toUtc().difference(startedAt.toUtc());

        final verdict = await resolveStuckPayment(
          insId: student.insId,
          payId: stuckId,
          orderId: row['payorderid']?.toString(),
        );

        switch (verdict.outcome) {
          case StuckPaymentOutcome.failed:
            // Paytm is certain no money was taken. Nothing is in flight any
            // more, so this attempt proceeds.
            debugPrint('in-flight pay_id=$stuckId failed at Paytm - retry allowed');
          case StuckPaymentOutcome.recovered:
            lastPaymentError =
                'Your earlier payment of ₹${stuckAmt.toStringAsFixed(0)} '
                'went through. The receipt is in History - please check there '
                'before paying again.';
            return null;
          case StuckPaymentOutcome.leftAlone:
            // Paytm has not decided -- AND IT MAY NEVER.
            //
            // An ABANDONED CHECKOUT looks exactly like a payment in progress
            // here. The parent opens the page, closes it without choosing a
            // method, and the order sits on Paytm's dashboard as Pending with
            // a BLANK payment source indefinitely; no callback is ever sent.
            // get-paytm-payment folds PENDING and NO_RECORD_FOUND into the
            // same 'pending', so nothing distinguishes the two from here.
            //
            // Blocking on that forever would lock the family out of paying at
            // all, which is worse than the double payment this guards against.
            // So the block is bounded: hold the window where the checkout page
            // is plausibly still open, then let them through.
            //
            // 15 minutes to match check_fees_locked, which is already the
            // house definition of "in flight". A genuine UPI or card payment
            // settles in seconds; one still undecided after a quarter of an
            // hour is almost always abandoned.
            //
            // The old row is deliberately LEFT AS 'I'. It is not failed here
            // -- Paytm never said so -- so if money does arrive against it
            // late, the webhook, the desktop sweep and fee_health_check all
            // still find it. Erasing it is what used to lose the money.
            if (stuckAge < const Duration(minutes: 15)) {
              lastPaymentError =
                  'A payment of ₹${stuckAmt.toStringAsFixed(0)} is still '
                  'being processed. Please wait a few minutes and check '
                  'History - if it succeeded the receipt appears on its own. '
                  'Do not pay again until then.';
              return null;
            }
            debugPrint('in-flight pay_id=$stuckId undecided after '
                '${stuckAge.inMinutes}min - treating as abandoned, retry '
                'allowed, row left as I for the recovery paths');
        }
      }
    } catch (e) {
      // A failed CHECK must not become a failed PAYMENT: this is a guard, and
      // the paths that catch a double payment afterwards (the webhook, the
      // desktop sweep, fee_health_check) are all still in place.
      debugPrint('in-flight payment check skipped: $e');
    }

    // 2. Check if these fees are already being paid on another device
    try {
      final lockedFees = await SupabaseService.client.rpc('check_fees_locked', params: {
        'p_dem_ids': items.map((f) => f.demId).toList(),
      });
      if ((lockedFees as List).isNotEmpty) {
        lastPaymentError = 'These fees are already being processed on another device. Please wait.';
        return null;
      }
    } catch (e) {
      // RPC not deployed yet - skip check (non-critical safety feature)
      debugPrint('check_fees_locked RPC not available: $e');
    }

    // 2b. Walk items → feedemand.fee_id → feetype.fg_id → feegroup once and
    // use the result for two checks:
    //   (i)  Every involved fee group must have a `sequence` row, otherwise
    //        the RPC falls back to a synthetic `PAY<pay_id>` receipt number
    //        — block here so the parent isn't charged for a payment that
    //        will end up with an ugly receipt and silent misconfiguration.
    //   (ii) Pick the most common ban_id across involved groups to stamp as
    //        the beneficiary bank on the 'I' row (admin parity; the gateway
    //        batches all groups into one transaction so we pick a majority).
    int? beneficiaryBanId;
    try {
      // Reuse the feedemand read from step 1 — fee_ids of the items still being
      // paid (already-paid demands were filtered out above).
      final payingDemIds = items.map((f) => f.demId).toSet();
      final feeIds = (freshDemands as List)
          .where((r) => payingDemIds.contains(r['dem_id']))
          .map((r) => r['fee_id'])
          .whereType<int>()
          .toSet()
          .toList();
      if (feeIds.isNotEmpty) {
        final ftRows = await SupabaseService.fromSchema('feetype')
            .select('fg_id')
            .inFilter('fee_id', feeIds);
        final fgIds = (ftRows as List)
            .map((r) => r['fg_id'])
            .whereType<int>()
            .toSet()
            .toList();
        if (fgIds.isNotEmpty) {
          // (i) Sequence-configured check. Mirrors the WHERE used inside
          // process_grouped_payment / complete_payment_grouped at the
          // `SELECT seq_id,sequid,seqwidth,seqcurno FROM <schema>.sequence
          //  WHERE ins_id=$1 AND fg_id=$2 LIMIT 1` step.
          // The sequence-configured check and the feegroup/ban read only depend
          // on fgIds and are independent — run them together to save a hop.
          final cfgChecks = await Future.wait([
            SupabaseService.fromSchema('sequence')
                .select('fg_id')
                .eq('ins_id', student.insId)
                .inFilter('fg_id', fgIds),
            SupabaseService.fromSchema('feegroup')
                .select('fg_id, ban_id, fgdesc')
                .inFilter('fg_id', fgIds),
          ]);
          final seqRows = cfgChecks[0];
          final fgRows = cfgChecks[1];
          final configured = (seqRows as List)
              .map((r) => r['fg_id'])
              .whereType<int>()
              .toSet();
          final missing =
              fgIds.where((fg) => !configured.contains(fg)).toList();
          if (missing.isNotEmpty) {
            // Log the specific misconfiguration so support can diagnose,
            // but show the parent a generic "try again later" message —
            // exposing fee-group names just confuses end users.
            try {
              final missingRows = await SupabaseService.fromSchema('feegroup')
                  .select('fg_id, fgdesc')
                  .inFilter('fg_id', missing);
              final names = (missingRows as List)
                  .map((r) =>
                      (r['fgdesc'] as String?)?.trim().isNotEmpty == true
                          ? r['fgdesc'] as String
                          : 'group #${r['fg_id']}')
                  .join(', ');
              debugPrint('Sequence missing for fee groups: $names');
            } catch (_) {/* logging only */}
            // A setup gap at the school, not an outage: say so plainly.
            lastPaymentError = 'Online payment is not set up for some of these fees yet. '
                'Please pay them at the school office.';
            return null;
          }

          // (ii) feegroup ban_id check: every involved fee group must have a
          // beneficiary bank mapped, otherwise Razorpay payments end up with
          // ban_id=NULL on the payment row and the per-bank routing reports
          // can't classify them. Block here with the same generic message
          // the sequence check uses so end users don't see implementation
          // details.
          final fgWithBan = <int, int>{};
          final fgNames = <int, String>{};
          for (final r in (fgRows as List)) {
            final fg = r['fg_id'];
            final ban = r['ban_id'];
            final name = (r['fgdesc'] as String?) ?? '';
            if (fg is int) {
              fgNames[fg] = name.trim().isEmpty ? 'group #$fg' : name;
              if (ban is int) fgWithBan[fg] = ban;
            }
          }
          final missingBank =
              fgIds.where((fg) => !fgWithBan.containsKey(fg)).toList();
          if (missingBank.isNotEmpty) {
            debugPrint(
              'Bank not mapped for fee groups: '
              '${missingBank.map((fg) => fgNames[fg] ?? 'group #$fg').join(', ')}',
            );
            // A setup gap at the school, not an outage: say so plainly.
            lastPaymentError = 'Online payment is not set up for some of these fees yet. '
                'Please pay them at the school office.';
            return null;
          }

          // ban_id majority vote across mapped groups.
          if (fgWithBan.isNotEmpty) {
            final counts = <int, int>{};
            for (final id in fgWithBan.values) {
              counts[id] = (counts[id] ?? 0) + 1;
            }
            final entry = counts.entries
                .reduce((a, b) => a.value >= b.value ? a : b);
            beneficiaryBanId = entry.key;
          }
        }
      }
    } catch (e) {
      // The sequence check above sets lastPaymentError + returns null on its
      // own failure path. This catch handles unexpected lookup failures
      // (table not found, network, etc.) — log and let the payment proceed;
      // the RPC's own fallback paynumber generation will still produce a row.
      debugPrint('Fee-group config check failed: $e');
    }

    // Build the per-demand items list in the shape admin's orphan-recovery
    // sweep expects. Stored on the 'I' row as `payitems` so if Razorpay
    // captures the payment but the success callback never fires, the admin's
    // `_sweepOrphanedPayments` can read these items and replay them through
    // `complete_payment_grouped` — same recovery path admin-initiated
    // payments use.
    // Arrear demands whose year isn't in the year master carry an invalid/zero
    // yr_id, but payment.yr_id / paymentdetails.yr_id are NOT NULL (and FK to
    // year). Fall back to the current active year — matches the admin app's
    // arrear collection (_currentYearId in student_fee_collection_screen).
    int? fallbackYrId;
    if (items.any((f) => f.yrId <= 0)) {
      try {
        final r = await SupabaseService.fromSchema('year')
            .select('yr_id')
            .eq('activestatus', 1)
            .order('yr_id', ascending: false)
            .limit(1)
            .maybeSingle();
        fallbackYrId = (r?['yr_id'] as num?)?.toInt();
      } catch (_) {}
    }
    int effYr(int y) => (y > 0) ? y : (fallbackYrId ?? y);

    final payItems = [
      for (final fee in items)
        {
          'dem_id': fee.demId,
          'yr_id': effYr(fee.yrId),
          'yrlabel': fee.demfeeyear,
          'ins_id': fee.insId,
          'amount': _payable(fee, partMap) + _fineFor(fee, fineMap, partMap),
          'demfeetype': fee.demfeetype,
        },
    ];

    // 3. Create payment record (paystatus = 'I' for Initiated, NO paynumber yet).
    // The paynumber is assigned by `complete_payment_grouped` RPC ONLY when the
    // payment succeeds (status 'C'). Failed payments stay paynumber-less so we
    // don't waste sequence numbers on aborted attempts (matches admin app).
    // recon_status='P' is set explicitly so admin's bank-reconciliation page
    // (which filters by recon_status='P') sees this payment regardless of
    // whether the column has a DB DEFAULT.
    // The payment + paymentdetails rows are inserted server-side by the
    // SECURITY DEFINER RPC (like the admin's collection RPCs), so the app needs
    // no direct anon write on those money tables (fixes 42501). The RPC also
    // clears stale 'I' rows and applies the current-year fallback for arrears.
    final detailItems = [
      for (final fee in items)
        {
          'dem_id': fee.demId,
          'yr_id': effYr(fee.yrId),
          'yrlabel': fee.demfeeyear,
          'amount': _payable(fee, partMap),
        },
    ];
    final rpcRes = await SupabaseService.client.rpc('create_pending_payment', params: {
      'p_ins_id': student.insId,
      'p_stu_id': student.stuId,
      'p_total': totalAmount,
      'p_yr_id': effYr(items.first.yrId),
      'p_yrlabel': items.first.demfeeyear,
      'p_created_by': parent?.payincharge ?? student.stuname,
      'p_payitems': jsonEncode(payItems),
      'p_details': detailItems,
      'p_ban_id': beneficiaryBanId,
    });
    final payId = (rpcRes as num).toInt();

    // Mark the cart as initiated (shoppingcart is not a revoked money table).
    await SupabaseService.fromSchema('shoppingcart').update({
      'carinitiated': 'I',
    }).eq('car_id', carId);

    debugPrint('Payment initiated via RPC: pay_id=$payId, ${items.length} detail rows (paynumber assigned on success)');
    return payId;
  } catch (e, stackTrace) {
    lastPaymentError = e.toString();
    debugPrint('Error initiating payment: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
}

/// Receipts already raised for this Paytm transaction, if any.
///
/// paytm-webhook and this app both write the Paytm txn id into payreference,
/// so a completed payment carrying our reference IS our receipt -- raised by
/// whichever of the two got there first.
///
/// Used to tell "the webhook beat me to it" (fine, show the receipt) apart
/// from "someone at the counter took this fee" (a real clash). Returns an
/// empty list on any error: an unanswered question must not be read as "no
/// receipt exists", because that is the reading that tells a parent their
/// successful payment needs refunding.
Future<List<int>> _receiptsAlreadyRaised(WidgetRef ref, String payreference) async {
  final ref0 = payreference.trim();
  if (ref0.isEmpty) return const [];
  try {
    final rows = await SupabaseService.fromSchema('payment')
        .select('pay_id')
        .eq('paystatus', 'C')
        .eq('activestatus', 1)
        .ilike('payreference', '%$ref0%');
    return [
      for (final r in (rows as List))
        if ((r as Map)['pay_id'] is num) (r['pay_id'] as num).toInt()
    ];
  } catch (e) {
    debugPrint('could not check for an existing receipt: $e');
    return const [];
  }
}

/// Step 4: Handle payment gateway response.
/// On success: update payment status, update feedemand, delete cart, clear memory.
Future<List<int>> handlePaymentSuccess({
  required WidgetRef ref,
  required int payId,
  required int carId,
  required String paymethod,
  required String payreference,
  required List<FeeModel> items,
  Map<int, double>? fineMap,
  Map<int, double>? partMap,
}) async {


  // complete_payment_grouped splits the 'I' row into one 'C' row per fee group,
  // so the original payId may no longer exist after success. Collect the new
  // ids from the RPC response to navigate the user to a real receipt.
  final List<int> newPayIds = [];
  try {
    final studentId = items.first.stuId;
    final student = ref.read(selectedStudentProvider);

    // 1. Try atomic RPC (same as admin app) — updates payment, feedemand,
    //    and paymentdetails in a single transaction
    try {
      final rpcItems = items.map((fee) {
        final fine = _fineFor(fee, fineMap, partMap);
        return {
          'dem_id': fee.demId,
          'amount': _payable(fee, partMap) + fine,
          'fine': fine,
          'demfeetype': fee.demfeetype,
        };
      }).toList();

      final rpcResult = await SupabaseService.client.rpc('complete_payment_grouped', params: {
        'p_pay_id': payId,
        'p_pay_method': paymethod,
        'p_pay_reference': payreference,
        'p_items': rpcItems,
        'p_ins_id': student?.insId ?? items.first.insId,
        'p_status': 'C',
      });

      if (rpcResult is List) {
        for (final row in rpcResult) {
          final id = row is Map ? row['pay_id'] : null;
          if (id is int) {
            newPayIds.add(id);
          } else if (id is num) {
            newPayIds.add(id.toInt());
          }
        }
      }

      debugPrint('Payment completed via RPC: pay_id=$payId, new_pay_ids=$newPayIds');

      // Persist fineamount per demand so the admin dashboard's FINE column
      // (which reads feedemand.fineamount) reflects mobile-collected fines.
      //
      // Through set_parent_demand_fines, NOT a direct table write: anon holds
      // SELECT only on feedemand on production, so the direct update this used
      // to do was denied and -- being inside a catch that only debugPrints --
      // silently dropped every fine a parent paid. One call for the whole
      // cart instead of a round trip per demand.
      if (fineMap != null && fineMap.isNotEmpty) {
        final fines = [
          for (final e in fineMap.entries)
            if (e.value > 0) {'dem_id': e.key, 'fine': e.value}
        ];
        if (fines.isNotEmpty) {
          try {
            await SupabaseService.client
                .rpc('set_parent_demand_fines', params: {'p_fines': fines});
          } catch (e) {
            // Still not fatal -- the money is already collected and the fine
            // rides inside paidamount; only the FINE column suffers. But it is
            // now a real failure worth seeing, not the expected outcome.
            debugPrint('Fine column update failed: $e');
          }
        }
      }
    } catch (rpcError) {
      // WAS THE WEBHOOK FASTER? Ask before calling this a race.
      //
      // complete_payment_grouped refuses when a demand is already settled,
      // and there are TWO ways that happens. One is a counter collection
      // taking the same fee -- a real clash, handled below. The other is
      // paytm-webhook receipting THIS payment seconds before the app got
      // here, which is not a clash at all: the receipt exists, it is
      // correct, and the parent has paid exactly once.
      //
      // Live, 13-10-2026:
      //     11:16:56  webhook_complete_payment   200
      //     11:16:59  complete_payment_grouped   400
      // That is the webhook winning, and FC26/04016 was raised properly.
      // Treated as a clash it would tell the parent to expect a refund and
      // flag the row REFUND-NEEDED -- inviting staff to return money the
      // college had correctly collected.
      //
      // The webhook writes the Paytm txn id into payreference, and so does
      // this app, so a 'C' row carrying our reference is our receipt.
      final webhookIds = await _receiptsAlreadyRaised(ref, payreference);
      if (webhookIds.isNotEmpty) {
        debugPrint('Webhook receipted this payment first: $webhookIds');
        return webhookIds;
      }

      // SQLSTATE P0001 is raised by complete_payment_grouped when a
      // concurrent collector already cleared one of the demands. The
      // Paytm capture has already happened, so the safe thing is to
      // surface the situation for staff to refund manually — NOT to run
      // the manual fallback below, which would silently over-credit the
      // feedemand row by the same amount the concurrent collector posted.
      final errStr = rpcError.toString();
      final isRace = errStr.contains('P0001') ||
          errStr.contains('already paid') ||
          errStr.contains('concurrent payment');
      if (isRace) {
        debugPrint('Race detected on complete_payment_grouped: $rpcError');
        // Mark the original 'I' row so admin reconciliation surfaces it as
        // "captured but needs refund" rather than letting the orphan sweep
        // retry it later (which would hit the same race guard).
        try {
          await SupabaseService.client.rpc('set_payment_status', params: {
            'p_ins_id': student?.insId,
            'p_pay_id': payId,
            'p_status': 'F',
            'p_method': paymethod,
            'p_reference': '$payreference (REFUND-NEEDED: concurrent payment)',
          });
        } catch (e) {
          debugPrint('Failed to mark race payment for refund: $e');
        }
        lastPaymentError =
            'Payment captured by Paytm, but the fee was just paid through another channel. '
            'Staff will refund this amount.';
        // Stop here — don't run the manual fallback (it would double-credit)
        // and don't pretend success. Return empty so the caller routes to a
        // failure / refund-pending screen instead of a receipt.
        return [];
      }

      // Fallback: manual updates if RPC not deployed
      debugPrint('complete_payment_grouped RPC not available, using fallback: $rpcError');

      // Update payment status
      await SupabaseService.fromSchema('payment').update({
        'paystatus': 'C',
        'paymethod': paymethod,
        'payreference': payreference,
        'paydate': DateTime.now().toIso8601String(),
      }).eq('pay_id', payId);

      // Fetch and update feedemand records
      final demands = await SupabaseService.fromSchema('feedemand')
          .select('dem_id, paidamount, balancedue')
          .inFilter('dem_id', items.map((f) => f.demId).toList())
          .eq('activestatus', 1);

      final paidMap = <int, double>{};
      for (final fee in items) {
        paidMap[fee.demId] = fee.balancedue;
      }

      for (final demand in (demands as List)) {
        final demId = demand['dem_id'] as int;
        final paidAmount = paidMap[demId] ?? 0;
        final currentPaid = (demand['paidamount'] as num?)?.toDouble() ?? 0;
        final currentBalance = (demand['balancedue'] as num?)?.toDouble() ?? 0;
        final newPaid = currentPaid + paidAmount;
        final newBalance = currentBalance - paidAmount;

        final fine = fineMap?[demId] ?? 0;
        final updateMap = <String, dynamic>{
          'paidamount': newPaid,
          'balancedue': newBalance <= 0 ? 0 : newBalance,
          'paidstatus': newBalance <= 0 ? 'P' : 'U',
          'pay_id': payId,
        };
        if (fine > 0) updateMap['fineamount'] = fine;

        await SupabaseService.fromSchema('feedemand')
            .update(updateMap)
            .eq('dem_id', demId);
      }
    }

    // 2. Clean up ALL carts for this student
    final allCarts = await SupabaseService.fromSchema('shoppingcart')
        .select('car_id')
        .eq('stu_id', studentId);

    final allCarIds = ((allCarts) as List)
        .map((c) => c['car_id'] as int)
        .toList();

    if (allCarIds.isNotEmpty) {
      await SupabaseService.fromSchema('shoppingcartdetails').delete().inFilter('car_id', allCarIds);
      await SupabaseService.fromSchema('shoppingcart').delete().inFilter('car_id', allCarIds);
      debugPrint('Deleted ${allCarIds.length} cart(s) for student $studentId');
    }

    // 3. Clear in-memory cart & refresh all related providers
    ref.read(cartProvider.notifier).clearCart();
    ref.invalidate(feesProvider);
    ref.invalidate(paymentsProvider);
    ref.invalidate(paidFeesByPaymentProvider);
    ref.invalidate(notificationsProvider);

    debugPrint('Payment success: pay_id=$payId, feedemand updated, carts cleaned');
    // Fallback: if the RPC was unavailable, the original payId is still 'I→C'
    // on the same row, so it stays valid for the receipt view.
    return newPayIds.isNotEmpty ? newPayIds : [payId];
  } catch (e, stackTrace) {
    debugPrint('Error handling payment success: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still try to delete the cart even if feedemand updates failed
    try {
      await SupabaseService.fromSchema('shoppingcartdetails').delete().eq('car_id', carId);
      await SupabaseService.fromSchema('shoppingcart').delete().eq('car_id', carId);
      ref.read(cartProvider.notifier).clearCart();
      debugPrint('Cart deleted in error recovery');
    } catch (_) {}
    return [];
  }
}

/// Handle payment failure — marks payment as 'F' (failed), resets the cart,
/// and clears any stale fineamount on attempted demands so the next attempt
/// recalculates the fine fresh (mirrors admin's `_processOnlinePayment` reset).
Future<bool> handlePaymentFailure({
  required WidgetRef ref,
  required int payId,
  required int carId,
  String? payReference,
  String? errorReason,
  List<int>? attemptedDemIds,
  /// The gateway order id, when the caller has it. Used to ask Paytm whether
  /// this really failed before the row is written off. Falls back to the
  /// payorderid on the payment row.
  String? orderId,
}) async {


  try {
    final student = ref.read(selectedStudentProvider);
    final reference = payReference != null
        ? 'Payment Failed: $payReference'
        : 'Payment Failed';

    // Reconstruct the items the original 'I' payment was attempting so the
    // RPC can split-into-fee-groups and write a paymentdetails audit row per
    // demand (matching admin's behaviour). Without this the 'F' row exists
    // but has no per-demand breakdown.
    List<Map<String, dynamic>> rpcItems = [];
    try {
      final details = await SupabaseService.fromSchema('paymentdetails')
          .select('dem_id, transtotalamount')
          .eq('pay_id', payId)
          .eq('activestatus', 1);
      final detailRows = (details as List).cast<Map<String, dynamic>>();
      if (detailRows.isNotEmpty) {
        final demIds = detailRows
            .map((d) => d['dem_id'] is int ? d['dem_id'] as int : int.parse(d['dem_id'].toString()))
            .toList();
        final demands = await SupabaseService.fromSchema('feedemand')
            .select('dem_id, demfeetype')
            .inFilter('dem_id', demIds);
        final typeByDem = <int, String>{};
        for (final row in (demands as List).cast<Map<String, dynamic>>()) {
          final id = row['dem_id'] is int ? row['dem_id'] as int : int.parse(row['dem_id'].toString());
          typeByDem[id] = (row['demfeetype'] as String?) ?? '';
        }
        rpcItems = detailRows.map((d) {
          final id = d['dem_id'] is int ? d['dem_id'] as int : int.parse(d['dem_id'].toString());
          return {
            'dem_id': id,
            'amount': (d['transtotalamount'] as num?)?.toDouble() ?? 0,
            'demfeetype': typeByDem[id] ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Failure-path items lookup error: $e');
    }

    // ASK PAYTM BEFORE WRITING THE PAYMENT OFF.
    //
    // This used to mark the row 'F' immediately, trusting the checkout's own
    // callback. That callback fires when the WINDOW ends -- including when the
    // parent simply closes it -- which is not the same as the BANK having
    // declined. A payment still settling was recorded as failed, the money
    // arrived afterwards, and nothing ever revisits an 'F' row: that is how
    // mobile payments ended up with no receipt behind them and had to be
    // entered by hand (Rs 91,500 over 28-30 Sep 2026).
    //
    // The Transaction Status API is the only authority. Three outcomes, not
    // one -- exactly how resolveStuckPayment already treats them:
    //   captured  -> complete it and raise the receipt, whatever the window said
    //   failed    -> a real decline; record it
    //   undecided -> leave the row 'I'. The sweep and the webhook both revisit
    //                an 'I' row; neither revisits an 'F'.
    final insId = student?.insId;
    var markedFailed = false;
    if (insId != null) {
      final outcome = await resolveStuckPayment(
        insId: insId,
        payId: payId,
        orderId: (orderId != null && orderId.trim().isNotEmpty)
            ? orderId.trim()
            : await _payOrderIdOf(payId),
      );
      markedFailed = outcome.outcome == StuckPaymentOutcome.failed;
      if (outcome.outcome == StuckPaymentOutcome.recovered) {
        // The parent paid after all, and the receipt has just been raised.
        // Treating this as a failure would reset the cart under a payment that
        // actually went through.
        ref.invalidate(paymentsProvider);
        ref.invalidate(notificationsProvider);
        debugPrint('handlePaymentFailure: pay_id=$payId was CAPTURED after all '
            'and has been completed');
        return false;
      }
    }

    // Only a confirmed decline gets the per-demand breakdown written against
    // it. An undecided payment keeps its 'I' row untouched so it stays
    // recoverable.
    if (markedFailed && rpcItems.isNotEmpty) {
      try {
        await SupabaseService.client.rpc('complete_payment_grouped', params: {
          'p_pay_id': payId,
          'p_pay_method': 'Online Transfer',
          'p_pay_reference': reference,
          'p_items': rpcItems,
          'p_ins_id': insId,
          'p_status': 'F',
        });
      } catch (e) {
        // The row is already 'F'; this only adds the breakdown, so a failure
        // here is not worth escalating.
        debugPrint('Failure-path breakdown skipped for pay_id=$payId: $e');
      }
    }

    // Reset cart
    await SupabaseService.fromSchema('shoppingcart').update({
      'carinitiated': 'N',
    }).eq('car_id', carId);

    // Reset fineamount on attempted demands so no stale fine value lingers.
    // Same RPC as the success path, for the same reason: a direct update is
    // refused on production and the stale fine stayed on the demand.
    if (attemptedDemIds != null && attemptedDemIds.isNotEmpty) {
      try {
        await SupabaseService.client.rpc('set_parent_demand_fines', params: {
          'p_fines': [for (final d in attemptedDemIds) {'dem_id': d, 'fine': 0}],
        });
      } catch (e) {
        debugPrint('Fine reset failed: $e');
      }
    }

    ref.invalidate(paymentsProvider);
    ref.invalidate(notificationsProvider);

    debugPrint('Payment failed: pay_id=$payId marked as F, cart car_id=$carId reset');
    return true;
  } catch (e) {
    debugPrint('Error handling payment failure: $e');
    return false;
  }
}

/// Result of an orphaned-payment sweep.
class OrphanSweepResult {
  final int recovered;  // 'I' payments that were captured by Razorpay (now 'C')
  final int failed;     // 'I' payments that did not capture (now 'F')
  const OrphanSweepResult({this.recovered = 0, this.failed = 0});
  bool get hasAny => recovered > 0 || failed > 0;
}

/// What happened when a stuck ('I') payment was checked with the gateway.
enum StuckPaymentOutcome { recovered, failed, leftAlone }

class StuckPaymentResult {
  final StuckPaymentOutcome outcome;

  /// Receipt pay_ids created on recovery (one per fee group).
  final List<int> newPayIds;

  const StuckPaymentResult(this.outcome, [this.newPayIds = const []]);
}

/// Resolve one stuck ('I') payment by asking the gateway that took it. Only a
/// definite answer changes the payment:
///   * captured          -> complete it (receipt + fee demand update);
///   * Paytm TXN_FAILURE -> mark it failed;
///   * anything else     -> LEAVE IT ALONE (pending, no record, routing or
///     lookup error, RPC error). The desktop Fee Collection sweep retries it.
/// A payment with no order id never reached a gateway, so it is marked failed.
///
/// Both callers used to ask only Razorpay and fail everything else, which for
/// Paytm meant a charged payment would be marked failed.
Future<StuckPaymentResult> resolveStuckPayment({
  required int insId,
  required int payId,
  String? orderId,
}) async {
  const leave = StuckPaymentResult(StuckPaymentOutcome.leftAlone);
  final oid = orderId?.trim() ?? '';

  Future<StuckPaymentResult> markFailed(String? reference) async {
    try {
      await SupabaseService.client.rpc('set_payment_status', params: {
        'p_ins_id': insId,
        'p_pay_id': payId,
        'p_status': 'F',
        if (reference != null) 'p_reference': reference,
        'p_touch_date': false,
      });
      return const StuckPaymentResult(StuckPaymentOutcome.failed);
    } catch (e) {
      debugPrint('resolveStuckPayment: mark failed pay_id=$payId: $e');
      return leave;
    }
  }

  if (oid.isEmpty) return markFailed(null);

  bool captured = false;
  bool failed = false;
  String? txnId;
  if (oid.startsWith('PAY-')) {
    // Paytm: ask under THE MERCHANT THE ORDER WAS CREATED WITH.
    //
    // Orders are signed per fee group now, so a hostel payment was created
    // under the hostel merchant. Asking the college merchant about it returns
    // "no such order", and this resolver would mark a payment the parent
    // actually made as failed. payment.ban_id is the group's bank, stamped
    // when the row was raised, so it names the merchant to ask.
    int? banId;
    try {
      final row = await SupabaseService.fromSchema('payment')
          .select('ban_id')
          .eq('pay_id', payId)
          .maybeSingle();
      banId = row?['ban_id'] as int?;
    } catch (e) {
      debugPrint('resolveStuckPayment: ban lookup pay_id=$payId: $e');
    }
    // Only ban_id is known here -- it is what the payment row carries.
    final routing =
        await SupabaseService.resolvePaytmRouting(insId: insId, banId: banId);
    if (!routing.ok) return leave;
    try {
      final st = await PaytmService.verifyPayment(oid, mid: routing.mid);
      captured = st.isCaptured && st.paymentId != null;
      failed = st.isFailed;
      txnId = st.paymentId;
    } catch (e) {
      debugPrint('resolveStuckPayment: Paytm lookup pay_id=$payId: $e');
      return leave;
    }
  } else {
    // Legacy Razorpay order: recover if captured, otherwise leave it.
    try {
      final resp = await SupabaseService.client.functions
          .invoke('get-razorpay-payment', body: {'order_id': oid});
      if (resp.status == 200 && resp.data is Map<String, dynamic>) {
        final data = resp.data as Map<String, dynamic>;
        if (data['status'] == 'captured' && data['payment_id'] != null) {
          captured = true;
          txnId = data['payment_id'].toString();
        }
      }
    } catch (e) {
      debugPrint('resolveStuckPayment: Razorpay lookup pay_id=$payId: $e');
      return leave;
    }
  }

  if (captured) {
    try {
      final items = await _stuckPaymentItems(payId);
      final result = await SupabaseService.client.rpc('complete_payment_grouped', params: {
        'p_pay_id': payId,
        'p_pay_method': 'Online Transfer',
        // Bare txn id, like a normal success, so Bank Reconciliation matches it.
        'p_pay_reference': txnId,
        'p_items': items,
        'p_ins_id': insId,
        'p_status': 'C',
      });
      final ids = <int>[];
      if (result is List) {
        for (final row in result) {
          final id = row is Map ? row['pay_id'] : null;
          if (id is num) ids.add(id.toInt());
        }
      }
      return StuckPaymentResult(
          StuckPaymentOutcome.recovered, ids.isEmpty ? [payId] : ids);
    } catch (e) {
      debugPrint('resolveStuckPayment: recovery pay_id=$payId: $e');
      return leave;
    }
  }
  if (failed) return markFailed('FAILED:$oid');
  return leave;
}

/// How long a parent must wait after an attempt that did not succeed before
/// starting another one.
///
/// WHY THIS EXISTS. A parent whose payment appears to fail retries immediately,
/// and each attempt opens a SEPARATE Paytm transaction. A transaction that
/// looks failed in the app may still be settling at the bank -- that is the
/// whole reason the failure path now asks Paytm rather than assuming. So a
/// quick retry can put two live transactions against the same dues and debit
/// the family twice, with only one receipt to show for it. On 2026-10-01 three
/// transactions totalling Rs 75,675 were opened within nine minutes and all
/// three sat pending.
///
/// Five minutes is long enough for the gateway to reach a verdict on the first
/// attempt, and the cooldown ends early the moment it does: a payment that
/// comes back CAPTURED has already cleared the dues, and one that comes back
/// genuinely FAILED releases the student straight away.
const kPaymentRetryCooldown = Duration(minutes: 5);

/// Time left before this student may start another online payment, or null if
/// they may pay now.
///
/// Reads the last attempt from the DATABASE rather than remembering it in the
/// app, so closing and reopening does not hand out a fresh attempt, and a
/// second device cannot start one either.
Future<Duration?> paymentRetryWait(int stuId) async {
  try {
    final rows = await SupabaseService.fromSchema('payment')
        .select('paystatus, createdat')
        .eq('stu_id', stuId)
        .inFilter('paystatus', ['I', 'F'])
        // The server's own guard covers the school's gateways.
        .isFilter('pg_id', null)
        .order('createdat', ascending: false)
        .limit(1);
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;

    final raw = list.first['createdat']?.toString() ?? '';
    if (raw.isEmpty) return null;
    // createdat is a naive timestamp written by the DB's now(), which Supabase
    // keeps in UTC. Parsing it without the marker would read it as device-local
    // and skew the wait by the timezone offset.
    final created =
        DateTime.parse(raw.endsWith('Z') || raw.contains('+') ? raw : '${raw}Z');
    final elapsed = DateTime.now().toUtc().difference(created);
    // A negative elapsed means the phone's clock is behind the server's, so the
    // comparison is not trustworthy at all. ALLOW the payment rather than
    // blocking on a signal we know is wrong: the cost of a missed cooldown is a
    // duplicate the sweep can recover, while the cost of blocking wrongly is a
    // parent who cannot pay and has no idea why. A phone with a badly set clock
    // must not be locked out of fees.
    if (elapsed.isNegative) return null;
    final left = kPaymentRetryCooldown - elapsed;
    return left.inSeconds > 0 ? left : null;
  } catch (e) {
    // A cooldown we cannot establish must not block a parent from paying.
    debugPrint('paymentRetryWait stu_id=$stuId: $e');
    return null;
  }
}

/// The gateway order id on a payment row, so the failure path can ask Paytm
/// about it. Returns null when the row has none -- resolveStuckPayment treats
/// that as "nothing to ask about".
Future<String?> _payOrderIdOf(int payId) async {
  try {
    final row = await SupabaseService.fromSchema('payment')
        .select('payorderid')
        .eq('pay_id', payId)
        .maybeSingle();
    final oid = row?['payorderid']?.toString().trim() ?? '';
    return oid.isEmpty ? null : oid;
  } catch (e) {
    debugPrint('_payOrderIdOf pay_id=$payId: $e');
    return null;
  }
}

/// The fee lines a stuck payment was for, rebuilt from paymentdetails so the
/// completion RPC takes its normal path (paynumber + fee demand update).
Future<List<Map<String, dynamic>>> _stuckPaymentItems(int payId) async {
  int idOf(dynamic v) => v is int ? v : int.parse(v.toString());
  final details = await SupabaseService.fromSchema('paymentdetails')
      .select('dem_id, transtotalamount')
      .eq('pay_id', payId)
      .eq('activestatus', 1);
  final rows = (details as List).cast<Map<String, dynamic>>();
  if (rows.isEmpty) return [];
  final demands = await SupabaseService.fromSchema('feedemand')
      .select('dem_id, demfeetype')
      .inFilter('dem_id', rows.map((d) => idOf(d['dem_id'])).toList());
  final typeByDem = <int, String>{
    for (final r in (demands as List).cast<Map<String, dynamic>>())
      idOf(r['dem_id']): (r['demfeetype'] as String?) ?? '',
  };
  return rows.map((d) {
    final id = idOf(d['dem_id']);
    return <String, dynamic>{
      'dem_id': id,
      'amount': (d['transtotalamount'] as num?)?.toDouble() ?? 0,
      'demfeetype': typeByDem[id] ?? '',
    };
  }).toList();
}

/// Resolve this student's stuck ('I') payments older than [minAgeMinutes],
/// each through [resolveStuckPayment]. Runs when a parent opens the home screen.
Future<OrphanSweepResult> sweepOrphanedPayments({
  required int insId,
  required int stuId,
  int minAgeMinutes = 15,
}) async {
  int recovered = 0;
  int failed = 0;
  try {
    final cutoff = DateTime.now()
        .subtract(Duration(minutes: minAgeMinutes))
        .toIso8601String();
    final orphans = await SupabaseService.fromSchema('payment')
        .select('pay_id, payorderid, createdat')
        .eq('ins_id', insId)
        .eq('stu_id', stuId)
        .eq('paystatus', 'I')
        // Orders of the school's own gateways are settled by the server.
        .isFilter('pg_id', null)
        .lt('createdat', cutoff);
    for (final p in (orphans as List)) {
      final orderId = p['payorderid']?.toString();
      final r = await resolveStuckPayment(
        insId: insId,
        payId: (p['pay_id'] as num).toInt(),
        orderId: orderId,
      );
      if (r.outcome == StuckPaymentOutcome.recovered) {
        recovered++;
        // Keep the day the MONEY WAS TAKEN. complete_payment_grouped stamps
        // NOW(), which is right for a payment completing normally and wrong
        // for one recovered later: a capture just after midnight, receipted
        // when the parent next opens the app, would leave the previous day's
        // collection short and never tying against the Paytm report. The date
        // is the 'I' row's createdat -- stamped by the server when the payment
        // was initiated, never this phone's clock.
        final startedAt = p['createdat']?.toString();
        if (orderId != null && orderId.isNotEmpty &&
            startedAt != null && startedAt.isNotEmpty) {
          try {
            await SupabaseService.client.rpc('backdate_recovered_payment',
                params: {
                  'p_ins_id': insId,
                  'p_order_id': orderId,
                  'p_when': startedAt,
                });
          } catch (e) {
            debugPrint('backdate_recovered_payment $orderId: $e');
          }
        }
      }
      if (r.outcome == StuckPaymentOutcome.failed) failed++;
    }
  } catch (e) {
    debugPrint('sweepOrphanedPayments error: $e');
  }
  return OrphanSweepResult(recovered: recovered, failed: failed);
}

/// Restores the in-memory cart from database on app restart.
/// Watches selectedStudentProvider - auto-triggers when student changes.
/// Uses the `get_active_cart_fees` RPC for a single DB round trip.
/// Falls back to 3 sequential queries if the RPC is not available.
final cartRestorerProvider = FutureProvider.autoDispose<void>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  if (student == null) return;


  final currentCart = ref.read(cartProvider);

  // If cart already has items for THIS student, skip loading
  if (currentCart.isNotEmpty && currentCart.studentId == student.stuId) {
    return;
  }

  // First, recover any abandoned 'I' (initiated) carts from failed/interrupted payments
  try {
    final abandonedCarts = await SupabaseService.fromSchema('shoppingcart')
        .select('car_id')
        .eq('stu_id', student.stuId)
        .eq('carinitiated', 'I')
        .eq('activestatus', 1);

    if ((abandonedCarts as List).isNotEmpty) {
      final abandonedCarIds = abandonedCarts.map((c) => c['car_id'] as int).toList();
      // Reset abandoned carts back to 'N' so RPC/fallback can find them
      await SupabaseService.fromSchema('shoppingcart').update({
        'carinitiated': 'N',
      }).inFilter('car_id', abandonedCarIds);

      // Delete orphaned 'I' payments (never completed) via grant-free RPC.
      try {
        final deleted = await SupabaseService.client.rpc('delete_stale_initiated_payments', params: {
          'p_ins_id': student.insId,
          'p_stu_id': student.stuId,
        });
        debugPrint('Deleted $deleted orphaned initiated payment(s)');
      } catch (e) {
        debugPrint('Orphan payment cleanup skipped: $e');
      }

      debugPrint('Reset ${abandonedCarIds.length} abandoned cart(s) from I to N');
    }

  } catch (e) {
    debugPrint('Error resetting abandoned carts: $e');
  }

  try {
    // Try single-query RPC first (requires running db_sync/setup_cart_rpc.sql)
    final fees = await SupabaseService.client.rpc('get_active_cart_fees', params: {
      'p_stu_id': student.stuId,
    });

    final allFees = (await SupabaseService.withFeeTypes(fees))
        .map((f) => FeeModel.fromJson(f))
        .toList();

    // Filter out already-paid fees (balancedue <= 0 or paidstatus = 'P')
    final unpaidFees = allFees.where((f) => f.balancedue > 0 && f.paidstatus != 'P').toList();
    final paidFees = allFees.where((f) => f.balancedue <= 0 || f.paidstatus == 'P').toList();

    // Clean up paid fee rows from DB
    if (unpaidFees.isEmpty && allFees.isNotEmpty) {
      await _cleanupPaidCart(student.stuId);
      debugPrint('All cart fees already paid — cart cleaned up');
    } else if (paidFees.isNotEmpty) {
      await _cleanupPaidCartItems(student.stuId, paidFees, unpaidFees);
    }

    ref.read(cartProvider.notifier).restoreCart(unpaidFees, student.stuId);
    if (unpaidFees.isNotEmpty) {
      debugPrint('Cart restored via RPC: ${unpaidFees.length} unpaid items for student ${student.stuId}');
    }
  } catch (rpcError) {
    // Fallback: 3 sequential queries (RPC not deployed yet)
    debugPrint('RPC fallback: $rpcError');
    try {
      // Abandoned 'I' carts were already reset to 'N' above, so just look for 'N'
      final cart = await SupabaseService.fromSchema('shoppingcart')
          .select('car_id')
          .eq('stu_id', student.stuId)
          .eq('carinitiated', 'N')
          .eq('activestatus', 1)
          .maybeSingle();

      if (cart == null) {
        ref.read(cartProvider.notifier).restoreCart([], student.stuId);
        return;
      }

      final carId = cart['car_id'] as int;

      // Get dem_ids from cart details
      final details = await SupabaseService.fromSchema('shoppingcartdetails')
          .select('dem_id')
          .eq('car_id', carId)
          .eq('activestatus', 1);

      final demIds = (details as List)
          .map((d) => d['dem_id'] is int ? d['dem_id'] as int : int.parse(d['dem_id'].toString()))
          .toList();

      if (demIds.isEmpty) {
        ref.read(cartProvider.notifier).restoreCart([], student.stuId);
        return;
      }

      // Fetch full feedemand records for these dem_ids
      final fees = await SupabaseService.fromSchema('feedemand')
          .select('*')
          .inFilter('dem_id', demIds)
          .eq('activestatus', 1);

      final allFees = (await SupabaseService.withFeeTypes(fees))
          .map((f) => FeeModel.fromJson(f))
          .toList();

      // Filter out already-paid fees
      final unpaidFees = allFees.where((f) => f.balancedue > 0 && f.paidstatus != 'P').toList();
      final paidFees = allFees.where((f) => f.balancedue <= 0 || f.paidstatus == 'P').toList();

      // Clean up paid fee rows from DB
      if (unpaidFees.isEmpty && allFees.isNotEmpty) {
        await _cleanupPaidCart(student.stuId);
        debugPrint('All cart fees already paid — cart cleaned up (fallback)');
      } else if (paidFees.isNotEmpty) {
        await _cleanupPaidCartItems(student.stuId, paidFees, unpaidFees);
      }

      ref.read(cartProvider.notifier).restoreCart(unpaidFees, student.stuId);
      if (unpaidFees.isNotEmpty) {
        debugPrint('Cart restored from DB: ${unpaidFees.length} unpaid items for student ${student.stuId}');
      }
    } catch (e) {
      debugPrint('Error restoring cart from database: $e');
      ref.read(cartProvider.notifier).restoreCart([], student.stuId);
    }
  }
});

/// A completed payment with its fee details
class PaidPaymentGroup {
  final PaymentModel payment;
  final List<FeeModel> fees;

  PaidPaymentGroup({required this.payment, required this.fees});
}

/// Paid fee groups sourced from payment + paymentdetails + feedemand tables.
/// More reliable than filtering feedemand by paidstatus (which can be stale).
final paidFeesByPaymentProvider = FutureProvider<Map<int, PaidPaymentGroup>>((ref) async {
  final student = ref.watch(selectedStudentProvider);

  if (student == null) return {};

  try {
    // 1. Get all completed payments
    final payments = await SupabaseService.fromSchema('payment')
        .select('*')
        .eq('stu_id', student.stuId)
        .eq('paystatus', 'C')
        .eq('activestatus', 1)
        .order('createdat', ascending: false);

    if ((payments as List).isEmpty) return {};

    final paymentModels = payments.map((p) => PaymentModel.fromJson(p)).toList();
    final payIds = paymentModels.map((p) => p.payId).toList();

    // 2. Get all payment details for these payments
    final details = await SupabaseService.fromSchema('paymentdetails')
        .select('*')
        .inFilter('pay_id', payIds)
        .eq('activestatus', 1);

    final detailModels = (details as List)
        .map((d) => PaymentDetailModel.fromJson(d))
        .toList();

    // Group details by pay_id
    final detailsByPayId = <int, List<PaymentDetailModel>>{};
    for (final detail in detailModels) {
      detailsByPayId.putIfAbsent(detail.payId, () => []).add(detail);
    }

    // 3. Get all feedemand records for the dem_ids (for fee names/terms)
    final allDemIds = detailModels.map((d) => d.demId).toSet().toList();
    if (allDemIds.isEmpty) {
      final result = <int, PaidPaymentGroup>{};
      for (final payment in paymentModels) {
        result[payment.payId] = PaidPaymentGroup(payment: payment, fees: []);
      }
      return result;
    }

    List<FeeModel> feeModels;
    try {
      final fees = await SupabaseService.fromSchema('feedemand')
          .select('*')
          .inFilter('dem_id', allDemIds);
      feeModels = (await SupabaseService.withFeeTypes(fees)).map((f) => FeeModel.fromJson(f)).toList();
    } catch (e) {
      final fees = await SupabaseService.fromSchema('feedemand')
          .select('*')
          .inFilter('dem_id', allDemIds);
      feeModels = (await SupabaseService.withFeeTypes(fees)).map((f) => FeeModel.fromJson(f)).toList();
    }

    // Map dem_id -> FeeModel
    final feeMap = <int, FeeModel>{};
    for (final fee in feeModels) {
      feeMap[fee.demId] = fee;
    }

    // 4. Build result: each payment with its fee details
    final result = <int, PaidPaymentGroup>{};
    for (final payment in paymentModels) {
      final payDetails = detailsByPayId[payment.payId] ?? [];
      final fees = payDetails
          .where((d) => feeMap.containsKey(d.demId))
          .map((d) {
            final fee = feeMap[d.demId]!;
            // Use the amount from paymentdetails (actual paid amount for this payment)
            return fee.copyWith(paidamount: d.transtotalamount);
          })
          .toList();

      result[payment.payId] = PaidPaymentGroup(payment: payment, fees: fees);
    }

    return result;
  } catch (e) {
    debugPrint('Error fetching paid fee groups: $e');
    return {};
  }
});

/// Helper: Remove individual paid fee rows from shoppingcartdetails (partial payment scenario)
/// Updates the cart total to reflect only unpaid fees remaining.
Future<void> _cleanupPaidCartItems(int stuId, List<FeeModel> paidFees, List<FeeModel> unpaidFees) async {
  try {
    final carts = await SupabaseService.fromSchema('shoppingcart')
        .select('car_id')
        .eq('stu_id', stuId)
        .eq('activestatus', 1);

    if ((carts as List).isEmpty) return;

    final carIds = carts.map((c) => c['car_id'] as int).toList();
    final paidDemIds = paidFees.map((f) => f.demId).toList();

    // Delete paid fee rows from shoppingcartdetails
    await SupabaseService.fromSchema('shoppingcartdetails')
        .delete()
        .inFilter('car_id', carIds)
        .inFilter('dem_id', paidDemIds);

    // Update cart header total to reflect only unpaid fees
    final newTotal = unpaidFees.fold<double>(0, (sum, f) => sum + f.balancedue);
    await SupabaseService.fromSchema('shoppingcart')
        .update({'transtotalamount': newTotal})
        .inFilter('car_id', carIds);

    debugPrint('Removed ${paidFees.length} paid fee(s) from cart details, updated total to $newTotal');
  } catch (e) {
    debugPrint('Error cleaning up paid cart items: $e');
  }
}

/// Helper: Delete stale shopping cart for a student whose fees are all paid
Future<void> _cleanupPaidCart(int stuId) async {
  try {
    final carts = await SupabaseService.fromSchema('shoppingcart')
        .select('car_id')
        .eq('stu_id', stuId)
        .eq('activestatus', 1);

    if ((carts as List).isNotEmpty) {
      final carIds = carts.map((c) => c['car_id'] as int).toList();
      await SupabaseService.fromSchema('shoppingcartdetails').delete().inFilter('car_id', carIds);
      await SupabaseService.fromSchema('shoppingcart').delete().inFilter('car_id', carIds);
      debugPrint('Deleted ${carIds.length} stale cart(s) for student $stuId (all fees paid)');
    }
  } catch (e) {
    debugPrint('Error cleaning up paid cart: $e');
  }
}


/// After the server has receipted an online payment made through the school's
/// own gateway (pay-status): the receipts already exist, so only the app's
/// cart and cached lists need to catch up.
Future<void> afterGatewayPayment(WidgetRef ref, int stuId) async {
  try {
    final carts = await SupabaseService.fromSchema('shoppingcart')
        .select('car_id')
        .eq('stu_id', stuId);
    final ids = (carts as List).map((c) => c['car_id'] as int).toList();
    if (ids.isNotEmpty) {
      await SupabaseService.fromSchema('shoppingcartdetails').delete().inFilter('car_id', ids);
      await SupabaseService.fromSchema('shoppingcart').delete().inFilter('car_id', ids);
    }
  } catch (e) {
    debugPrint('afterGatewayPayment cart cleanup: $e');
  }
  ref.read(cartProvider.notifier).clearCart();
  ref.invalidate(feesProvider);
  ref.invalidate(paymentsProvider);
  ref.invalidate(paidFeesByPaymentProvider);
  ref.invalidate(notificationsProvider);
}
