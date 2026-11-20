import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fee_model.dart';
import '../../core/services/supabase_service.dart';
import 'auth_provider.dart';
import 'student_provider.dart';

/// Cart state model containing selected fees for payment
class CartState {
  final List<FeeModel> items;
  final int studentId;

  /// feeId -> the amount the parent chose to pay, when it is LESS than the
  /// balance. Absent means "the whole balance".
  ///
  /// Held here rather than on FeeModel because FeeModel.balancedue is read all
  /// over the app as "what is owed"; a part payment changes what is being paid
  /// now, not what is owed. Keeping them separate means no existing screen can
  /// mistake one for the other.
  final Map<String, double> partAmounts;

  /// Set when a fee was refused because the cart already holds another fee
  /// group's dues, for the screen to show. Cleared on the next successful add
  /// or removal, so it never lingers.
  final String? blockedNote;

  const CartState({
    this.items = const [],
    this.studentId = 0,
    this.partAmounts = const {},
    this.blockedNote,
  });

  CartState copyWith({
    List<FeeModel>? items,
    int? studentId,
    Map<String, double>? partAmounts,
    String? blockedNote,
  }) {
    return CartState(
      items: items ?? this.items,
      studentId: studentId ?? this.studentId,
      partAmounts: partAmounts ?? this.partAmounts,
      // Explicitly passed, or dropped: a stale note outliving its cause is
      // worse than none.
      blockedNote: blockedNote,
    );
  }

  /// The fee group this cart is paying, by name. Null while it is empty.
  ///
  /// One cart = one group, because one Paytm order settles to ONE merchant
  /// and each group banks into its own account.
  String? get groupName {
    for (final f in items) {
      final g = f.feeGroupName.trim();
      if (g.isNotEmpty) return g;
    }
    return null;
  }

  /// What will actually be charged for this fee. Clamped to the balance, so a
  /// stale part amount can never exceed what is owed.
  double amountFor(FeeModel fee) {
    final part = partAmounts[fee.id];
    if (part == null || part <= 0 || part >= fee.balancedue) return fee.balancedue;
    return part;
  }

  /// dem_id -> chosen amount, for the payment path.
  Map<int, double> get partMapByDemId => {
        for (final f in items)
          if (amountFor(f) < f.balancedue) f.demId: amountFor(f),
      };

  // Computed properties
  int get itemCount => items.length;
  double get totalAmount => items.fold(0.0, (sum, fee) => sum + amountFor(fee));
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  bool containsFee(String feeId) => items.any((f) => f.id == feeId);
  Set<String> get feeIds => items.map((f) => f.id).toSet();
}

/// Cart state notifier for managing fee selections with real-time Supabase sync
class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;
  Timer? _syncTimer;
  bool _skipSync = false;

  CartNotifier(this._ref) : super(const CartState());

  /// Set a part amount for one fee. Pass null (or the full balance) to go back
  /// to paying it in full.
  void setPartAmount(String feeId, double? amount) {
    final next = Map<String, double>.from(state.partAmounts);
    if (amount == null || amount <= 0) {
      next.remove(feeId);
    } else {
      next[feeId] = amount;
    }
    state = state.copyWith(partAmounts: next);
    _scheduleSyncToDatabase();
  }

  /// Add single fee to cart.
  ///
  /// Returns false when the fee was REFUSED because the cart already holds
  /// another fee group's dues. College fees and hostel fees are banked into
  /// different accounts and a Paytm order settles to one merchant, so they
  /// cannot be paid together -- and the honest place to say so is here, when
  /// the parent taps Add, not at the end when they press Pay.
  bool addFee(FeeModel fee) {
    if (state.containsFee(fee.id)) return true;

    // Clear cart if switching students
    if (state.isNotEmpty && state.studentId != fee.stuId) {
      state = CartState(items: [fee], studentId: fee.stuId);
      _scheduleSyncToDatabase();
      return true;
    }

    final inCart = state.groupName;
    final incoming = fee.feeGroupName.trim();
    if (inCart != null &&
        incoming.isNotEmpty &&
        inCart.toUpperCase() != incoming.toUpperCase()) {
      state = state.copyWith(
        blockedNote: '$incoming is paid separately from $inCart — they go to '
            'different accounts. Pay what is in the cart first, or remove it.',
      );
      return false;
    }

    state = state.copyWith(
      items: [...state.items, fee],
      studentId: fee.stuId,
    );
    _scheduleSyncToDatabase();
    return true;
  }

  /// Add several fees. Those of another group are SKIPPED rather than
  /// silently mixed in, and [CartState.blockedNote] then says so.
  ///
  /// Returns how many were refused.
  int addFees(List<FeeModel> fees) {
    var refused = 0;
    _skipSync = true;
    for (int i = 0; i < fees.length - 1; i++) {
      if (!addFee(fees[i])) refused++;
    }
    _skipSync = false;
    if (fees.isNotEmpty) {
      if (!addFee(fees.last)) refused++;
    }
    return refused;
  }

  /// Remove single fee from cart
  void removeFee(String feeId) {
    state = state.copyWith(
      items: state.items.where((f) => f.id != feeId).toList(),
    );
    _scheduleSyncToDatabase();
  }

  /// Toggle fee in cart (add if not present, remove if present).
  /// False means the add was refused -- see [addFee].
  bool toggleFee(FeeModel fee) {
    if (state.containsFee(fee.id)) {
      removeFee(fee.id);
      return true;
    }
    return addFee(fee);
  }

  /// Restore cart from database (on app restart or student switch), applying
  /// the SAME one-group rule addFee applies.
  ///
  /// addFee guards the door; this used to come in through the window. A cart
  /// saved while the fee group could not be determined -- which is what happens
  /// when the feetype/feegroup embed fails and every fee reports an empty group
  /// -- came back mixed, and nothing re-checked it. The parent then reached
  /// checkout before being told the two cannot be paid together, because one
  /// Paytm order settles to exactly one merchant.
  ///
  /// Items whose group is UNKNOWN are kept: an empty group name is not evidence
  /// of a different group, and dropping them would empty carts for a reason the
  /// parent could do nothing about.
  void restoreCart(List<FeeModel> items, int studentId) {
    _syncTimer?.cancel();
    _skipSync = true;

    String? group;
    for (final f in items) {
      final g = f.feeGroupName.trim();
      if (g.isNotEmpty) {
        group = g;
        break;
      }
    }

    final kept = group == null
        ? items
        : items.where((f) {
            final g = f.feeGroupName.trim();
            return g.isEmpty || g.toUpperCase() == group!.toUpperCase();
          }).toList();
    final dropped = items.length - kept.length;

    state = kept.isEmpty
        ? const CartState()
        : CartState(
            items: kept,
            studentId: studentId,
            blockedNote: dropped == 0
                ? null
                : '$dropped fee(s) from another group were removed — they are '
                    'paid separately from $group and go to a different account.',
          );
    _skipSync = false;
    // The saved cart no longer matches what is held, so write the corrected one
    // back rather than leaving the mixed version to be restored again tomorrow.
    if (dropped > 0) _scheduleSyncToDatabase();
  }

  /// Clear all items from cart and delete from database (user explicitly clears)
  void clearCart() {
    _syncTimer?.cancel();
    state = const CartState();
    _syncToDatabase();
  }

  /// Clear in-memory cart only (used for student switch, does NOT delete from DB)
  void clearCartLocal() {
    _syncTimer?.cancel();
    state = const CartState();
  }

  /// Check if fee is in cart
  bool isInCart(String feeId) => state.containsFee(feeId);

  /// Schedule a debounced sync to Supabase (500ms delay)
  void _scheduleSyncToDatabase() {
    if (_skipSync) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 500), () {
      _syncToDatabase();
    });
  }

  // Serialize concurrent syncs. The 500ms debounce only prevents *pending*
  // timers from stacking; once a sync is mid-flight, a new tap that fires the
  // next timer raced the in-flight one — symptom was a FK violation where a
  // delete + concurrent insert hit shoppingcartdetails for a freshly-removed
  // car_id. Chain new syncs onto the previous future.
  Future<void> _syncInFlight = Future.value();

  Future<void> _syncToDatabase() {
    final next = _syncInFlight.then((_) => _syncToDatabaseInner());
    _syncInFlight = next.catchError((_) {});
    return next;
  }

  /// Sync current cart state to Supabase shoppingcart + shoppingcartdetails
  Future<void> _syncToDatabaseInner() async {
    final student = _ref.read(selectedStudentProvider);
    if (student == null) return;

    final parent = _ref.read(currentParentProvider);

    try {
      // Find existing active (non-initiated) cart for this student
      final existingCart = await SupabaseService.fromSchema('shoppingcart')
          .select('car_id')
          .eq('stu_id', student.stuId)
          .eq('carinitiated', 'N')
          .eq('activestatus', 1)
          .maybeSingle();

      // If cart is empty, delete existing cart from database
      if (state.isEmpty) {
        if (existingCart != null) {
          final carId = existingCart['car_id'] as int;
          await SupabaseService.fromSchema('shoppingcartdetails').delete().eq('car_id', carId);
          await SupabaseService.fromSchema('shoppingcart').delete().eq('car_id', carId);
          debugPrint('Cart deleted from DB: car_id=$carId');
        }
        return;
      }

      final items = state.items;
      final firstFee = items.first;
      // The chosen amounts, not the balances -- the cart header total has to
      // agree with the sum of its detail rows or the payment page shows one
      // figure and the gateway charges another.
      final totalAmount = items.fold<double>(0, (sum, f) => sum + state.amountFor(f));

      int carId;

      if (existingCart != null) {
        carId = existingCart['car_id'] as int;

        // Update cart header
        await SupabaseService.fromSchema('shoppingcart').update({
          'yr_id': firstFee.yrId,
          'yrlabel': firstFee.demfeeyear,
          'transdate': DateTime.now().toIso8601String().split('T')[0],
          'transtotalamount': totalAmount,
          'createdby': parent?.payincharge ?? student.stuname,
        }).eq('car_id', carId);

        // Delete old cart details
        await SupabaseService.fromSchema('shoppingcartdetails').delete().eq('car_id', carId);
      } else {
        // Create new cart
        final cartResponse = await SupabaseService.fromSchema('shoppingcart').insert({
          'yr_id': firstFee.yrId,
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

      // Insert new detail rows
      final detailRows = items.map((fee) => {
        'car_id': carId,
        'yr_id': fee.yrId,
        'yrlabel': fee.demfeeyear,
        'ins_id': fee.insId,
        'dem_id': fee.demId,
        'transcurrency': 'INR',
        'transtotalamount': state.amountFor(fee),
      }).toList();

      await SupabaseService.fromSchema('shoppingcartdetails').insert(detailRows);

      debugPrint('Cart synced to DB: car_id=$carId, ${items.length} items, total=$totalAmount');
    } catch (e) {
      debugPrint('Cart sync error: $e');
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

/// Cart provider with real-time Supabase sync
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

/// Convenience provider for cart item count
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});

/// Convenience provider for cart total amount
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).totalAmount;
});

/// Convenience provider for checking if cart is empty
final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).isEmpty;
});
