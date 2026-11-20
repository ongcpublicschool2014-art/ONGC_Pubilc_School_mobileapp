import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_ui.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/fee_group_utils.dart';
import '../../../config/routes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/fee_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/app_action_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/app_icon_circle_button.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

class AllPendingFeesScreen extends ConsumerStatefulWidget {
  final String? filterGroup;
  final String? filterStatus; // 'overdue', 'dueSoon', or null for all

  const AllPendingFeesScreen({super.key, this.filterGroup, this.filterStatus});

  @override
  ConsumerState<AllPendingFeesScreen> createState() => _AllPendingFeesScreenState();
}

class _AllPendingFeesScreenState extends ConsumerState<AllPendingFeesScreen> {
  String? _selectedSubFilter; // Sub-filter within the current fee group (e.g., "I TERM", "January")
  bool _isDropdownOpen = false;
  bool _showCartPreview = false;
  final Set<String> _localSelectedFeeIds = {}; // Local selection before adding to cart
  bool _initializedFromCart = false;

  /// dem_id -> {payable, partial_allowed, blocked_by}, from the database.
  ///
  /// The payment order (bus first, exam last, arrears before current-year fees)
  /// is configured per fee type in the admin app, so it is NOT decided here by
  /// matching fee names. Empty until loaded, and empty on any failure, which
  /// leaves every fee selectable -- a hiccup in this check must never stop a
  /// parent paying.
  Map<String, Map<String, dynamic>> _payOrder = const {};

  @override
  void initState() {
    super.initState();
    _selectedSubFilter = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPayOrder());
  }

  Future<void> _loadPayOrder() async {
    final student = ref.read(selectedStudentProvider);
    if (student == null) return;
    final map = await SupabaseService.checkFeePaymentOrder(
        student.insId, student.stuId);
    if (mounted) setState(() => _payOrder = map);
  }

  // NOTE: the server's own `payable` / `blocked_by` fields are deliberately no
  // longer used for gating. They are computed against outstanding demands with
  // no knowledge of what is selected, so they can only ever say "held behind
  // something" -- never "and you just ticked it". _unmetBlockers below answers
  // the question the cart actually asks.

  /// Clearance rank from the server: LOWER is paid first. A fee the check
  /// does not cover sorts last and blocks nothing.
  static const int _unranked = 1 << 30;
  int _rankOf(FeeModel f) =>
      (_payOrder[f.id]?['rank'] as num?)?.toInt() ?? _unranked;

  /// Outstanding fees ranked BELOW [f] that are neither cleared nor part of
  /// this selection. Empty means [f] may be selected now.
  ///
  /// Selection-aware, and that is the whole point. The server rule is "every
  /// lower-ranked demand is clear OR fully covered by this same payment", so
  /// once the bus fee is ticked the tuition fee behind it becomes selectable.
  /// The server's own `payable` flag cannot express that -- it is computed
  /// against outstanding demands with no knowledge of the cart -- so gating
  /// selection on it alone made it impossible to pay two ranked fees together,
  /// even though the server would have accepted exactly that.
  List<String> _unmetBlockers(FeeModel f, {Set<String> alsoSelected = const {}}) {
    final myRank = _rankOf(f);
    if (myRank == _unranked) return const [];
    final names = <String>{};
    _payOrder.forEach((demId, row) {
      final r = (row['rank'] as num?)?.toInt();
      if (r == null || r >= myRank) return;
      if (_localSelectedFeeIds.contains(demId) || alsoSelected.contains(demId)) {
        return; // covered by this same payment
      }
      var n = (row['demfeetype'] ?? '').toString().trim();
      if (n.isEmpty) n = 'an earlier fee';
      // "clear ARREAR TUITION FEE" means nothing to a parent; naming it as
      // last year's dues does.
      final arrear = (row['demseqtype'] ?? '').toString().trim().toUpperCase();
      names.add(arrear == 'ARREAR' ? "earlier years' dues (\$n)" : n);
    });
    return names.toList()..sort();
  }

  /// Names of already-selected fees that would be left unpayable if [removing]
  /// were dropped. Removing a fee that something else is riding on has to be
  /// refused, or the parent can unpick the bus fee and leave the tuition fee
  /// selected -- which the server would then reject at the worst possible
  /// moment, after the gateway has been opened.
  ///
  /// _payOrder holds only OUTSTANDING demands, so a lower-ranked entry missing
  /// from the remaining selection is genuinely unmet, never merely paid.
  List<String> _strandedBy(Set<String> removing) {
    final remaining = _localSelectedFeeIds.difference(removing);
    final names = <String>{};
    for (final id in remaining) {
      final row = _payOrder[id];
      final r = (row?['rank'] as num?)?.toInt();
      if (r == null) continue;
      var unmet = false;
      _payOrder.forEach((otherId, other) {
        final o = (other['rank'] as num?)?.toInt();
        if (o == null || o >= r) return;
        if (!remaining.contains(otherId)) unmet = true;
      });
      if (unmet) {
        final n = (row?['demfeetype'] ?? '').toString().trim();
        names.add(n.isEmpty ? 'a later fee' : n);
      }
    }
    return names.toList()..sort();
  }

  /// Shown when the parent tries to untick something a later fee depends on.
  void _showPriorityRemoveMessage(List<String> stranded) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const AppIcon('warning-2', color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Remove ${stranded.join(', ')} first -- it can only be paid '
                'together with this one.',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Is some SELECTED fee ranked after this one?
  bool _hasLaterSelected(FeeModel fee) {
    final myRank = _rankOf(fee);
    if (myRank == _unranked) return false;
    for (final id in _localSelectedFeeIds) {
      if (id == fee.id) continue;
      final r = (_payOrder[id]?['rank'] as num?)?.toInt();
      if (r != null && r > myRank) return true;
    }
    return false;
  }

  /// Whether this fee may be part-paid RIGHT NOW.
  ///
  /// Two conditions. The fee type must permit it (configured per fee type in
  /// the admin app, not decided here by matching names) -- and nothing ranked
  /// after it may be in the same selection.
  ///
  /// The second is the server's rule, not a nicety: a blocker only counts as
  /// satisfied when the payment covers its WHOLE balance, so part-paying an
  /// earlier fee while a later one is selected would leave the later one
  /// refused. Paying that fee on its own still allows a part payment.
  bool _partialAllowed(FeeModel fee) =>
      _payOrder[fee.id]?['partial_allowed'] == true && !_hasLaterSelected(fee);

  /// Selecting a later fee forces every earlier selected fee back to its full
  /// balance. Done here rather than left to the server so the parent sees the
  /// figure change while choosing, instead of being refused at the gateway.
  void _resetPartAmountsBelow(int rank) {
    if (rank == _unranked) return;
    final cart = ref.read(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final reset = <String>[];
    for (final id in _localSelectedFeeIds) {
      final r = (_payOrder[id]?['rank'] as num?)?.toInt();
      if (r == null || r >= rank) continue;
      if (!cart.partAmounts.containsKey(id)) continue;
      notifier.setPartAmount(id, null);
      final n = (_payOrder[id]?['demfeetype'] ?? '').toString().trim();
      reset.add(n.isEmpty ? 'an earlier fee' : n);
    }
    if (reset.isEmpty || !mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${reset.join(', ')} must be paid in full when a later fee '
          'is paid with it.'),
      backgroundColor: AppColors.warning,
      behavior: SnackBarBehavior.floating,
    ));
  }

  /// Ask for the amount to pay for one fee. Capped at the balance -- a part
  /// payment is "pay less now", never "pay more".
  ///
  /// Lives on THIS screen, next to the fee being chosen, rather than in the
  /// cart: the parent decides how much of a fee to pay at the moment they pick
  /// it, so the cart is only a confirmation of what was already decided.
  Future<void> _editPartAmount(FeeModel fee) async {
    final cart = ref.read(cartProvider);
    final current = cart.amountFor(fee);
    final ctrl = TextEditingController(
        text: current == fee.balancedue ? '' : current.toStringAsFixed(0));
    final money = NumberFormat('#,##,###');

    /// The reason this amount is not acceptable, or null when it is.
    /// Blank is acceptable -- it means pay the whole balance.
    String? problem(String raw) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      final v = double.tryParse(t);
      if (v == null) return 'Enter a number';
      if (v <= 0) return 'Enter an amount greater than 0';
      if (v > fee.balancedue) {
        return 'Cannot be more than ₹ ${money.format(fee.balancedue.toInt())}';
      }
      return null;
    }

    final entered = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          // Validated in the field as it is typed, so an over-payment is shown
          // under the box and Set is unavailable -- rather than accepting the
          // figure, closing, and explaining the refusal in a snackbar after the
          // dialog has gone.
          final err = problem(ctrl.text);
          final canSet = err == null && ctrl.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text(fee.demfeetype,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance  ₹ ${money.format(fee.balancedue.toInt())}',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  // Digits and one decimal point only -- a stray letter or
                  // currency symbol should never reach the parse.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setLocal(() {}),
                  onSubmitted: (_) {
                    if (canSet) {
                      Navigator.pop(ctx, double.tryParse(ctrl.text.trim()));
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Amount to pay now',
                    hintText: 'Leave blank to pay in full',
                    border: const OutlineInputBorder(),
                    prefixText: '₹ ',
                    errorText: err,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, fee.balancedue),
                child: const Text('Pay in full'),
              ),
              ElevatedButton(
                // Disabled while the amount is empty or invalid.
                onPressed: canSet
                    ? () => Navigator.pop(ctx, double.tryParse(ctrl.text.trim()))
                    : null,
                child: const Text('Set'),
              ),
            ],
          );
        },
      ),
    );
    if (entered == null) return;
    // Belt and braces: the field cannot produce this, but the amount must never
    // exceed the balance even if this is ever called from somewhere else.
    if (entered > fee.balancedue) return;
    ref.read(cartProvider.notifier).setPartAmount(
        fee.id, entered >= fee.balancedue ? null : entered);
    if (mounted) setState(() {});
  }

  /// Splits one class's fees into semester/term sections, each ordered by the
  /// rank of its earliest-clearing fee.
  ///
  /// A flat list of fee names does not tell a parent which instalment they are
  /// looking at; "IV SEM" does. Ordering the sections by rank rather than by
  /// name keeps the section they must clear first at the top, which is the same
  /// rule the rows inside follow.
  List<MapEntry<String, List<FeeModel>>> _byTerm(List<FeeModel> fees) {
    final m = <String, List<FeeModel>>{};
    for (final f in fees) {
      final k = f.demfeeterm.trim().isNotEmpty ? f.demfeeterm.trim() : 'Fees';
      m.putIfAbsent(k, () => []).add(f);
    }
    // Rows inside a section follow the same rule as the sections themselves,
    // so the arrear card -- which has no sort of its own -- is ordered too.
    for (final g in m.values) {
      g.sort((a, b) {
        final r = _rankOf(a).compareTo(_rankOf(b));
        return r != 0 ? r : a.demfeetype.compareTo(b.demfeetype);
      });
    }
    int groupRank(List<FeeModel> g) =>
        g.map(_rankOf).fold(_unranked, (a, b) => a < b ? a : b);
    return m.entries.toList()
      ..sort((a, b) {
        final r = groupRank(a.value).compareTo(groupRank(b.value));
        return r != 0 ? r : a.key.compareTo(b.key);
      });
  }

  /// Rows for one class, split into term sections -- but the term heading is
  /// only drawn when the card actually holds more than one term. With one card
  /// per semester it would otherwise just repeat the card's own subtitle.
  List<Widget> _termSections(BuildContext context, List<FeeModel> fees,
      Widget Function(FeeModel) row) {
    final sections = _byTerm(fees);
    final out = <Widget>[];
    for (final sec in sections) {
      if (sections.length > 1) {
        out.add(_termHeader(context, sec.key,
            sec.value.isNotEmpty ? sec.value.first.demfeeyear : ''));
      }
      out.addAll(sec.value.map(row));
    }
    return out;
  }

  /// The small heading above each semester section.
  Widget _termHeader(BuildContext context, String term, String year) => Padding(
        padding: const EdgeInsets.only(left: 19, top: 8, bottom: 2),
        child: Text(
          year.trim().isEmpty ? term.toUpperCase() : '${term.toUpperCase()}  ·  $year',
          style: TextStyle(
            fontSize: AppSizes.textSm,
            fontWeight: AppSizes.fontSemibold,
            color: AppColors.textSecondaryC(context),
            letterSpacing: 0.3,
          ),
        ),
      );

  /// Check if a fee is a bus/transport/van fee (checks both demfeetype and feeGroupName)
  bool _isBusFee(FeeModel f) {
    final lowerType = f.demfeetype.toLowerCase();
    final lowerGroup = f.feeGroupName.toLowerCase();
    return lowerType.contains('bus') || lowerType.contains('transport') || lowerType.contains('van') ||
           lowerGroup.contains('bus') || lowerGroup.contains('transport') || lowerGroup.contains('van');
  }

  /// Check if a fee is a tuition fee
  bool _isTuitionFee(FeeModel f) {
    final lowerType = f.demfeetype.toLowerCase();
    final lowerGroup = f.feeGroupName.toLowerCase();
    return lowerType.contains('tuition') || lowerGroup.contains('tuition');
  }

  /// Check if a fee is a hostel fee
  bool _isHostelFee(FeeModel f) {
    final lowerType = f.demfeetype.toLowerCase();
    final lowerGroup = f.feeGroupName.toLowerCase();
    return lowerType.contains('hostel') || lowerGroup.contains('hostel');
  }

  /// Check if a fee is an exam fee
  bool _isExamFee(FeeModel f) {
    final lowerType = f.demfeetype.toLowerCase();
    final lowerGroup = f.feeGroupName.toLowerCase();
    return lowerType.contains('exam') || lowerGroup.contains('exam');
  }

  @override
  Widget build(BuildContext context) {
    final allPendingFees = ref.watch(pendingFeesProvider);
    final cartState = ref.watch(cartProvider);

    // Initialize local selection from cart on first build
    if (!_initializedFromCart && cartState.isNotEmpty) {
      _localSelectedFeeIds.addAll(cartState.feeIds);
      _initializedFromCart = true;
    } else if (!_initializedFromCart) {
      _initializedFromCart = true;
    }

    // Apply filter based on filterGroup parameter (the main group from navigation)
    List<FeeModel> filteredFees;
    final activeFilterGroup = widget.filterGroup;

    if (activeFilterGroup != null &&
        activeFilterGroup.toUpperCase().contains('ARREAR')) {
      // "Arrear Fees" is a synthetic group (no demand carries it as a real
      // fee-group name), so match arrears by their demseqtype instead — and it
      // shows ONLY arrears.
      filteredFees = allPendingFees.where((f) => f.isArrear).toList();
    } else if (activeFilterGroup != null && activeFilterGroup.isNotEmpty) {
      // A real fee group (e.g. College Fee) shows ONLY its REGULAR fees —
      // arrears live exclusively on the separate Arrear Fees card.
      filteredFees = ref
          .watch(pendingFeesByGroupNameProvider(activeFilterGroup))
          .where((f) => !f.isArrear)
          .toList();
    } else {
      filteredFees = allPendingFees;
    }

    // Apply status filter (overdue/dueSoon)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thirtyDaysFromNow = today.add(const Duration(days: 30));
    if (widget.filterStatus == 'overdue') {
      filteredFees = filteredFees.where((f) => f.dueDate.isBefore(today)).toList();
    } else if (widget.filterStatus == 'dueSoon') {
      // Due soon = today or future AND within next 30 days
      filteredFees = filteredFees.where((f) =>
        !f.dueDate.isBefore(today) && f.dueDate.isBefore(thirtyDaysFromNow)
      ).toList();
    }


    // Arrear demands are shown in their own section and kept OUT of the regular
    // category groups so nothing double-shows.
    final arrearFees = filteredFees.where((f) => f.isArrear).toList();
    final regularFees = filteredFees.where((f) => !f.isArrear).toList();

    // Separate REGULAR fees by category
    final termFees = regularFees.where((f) => !_isBusFee(f) && !_isTuitionFee(f) && !_isHostelFee(f) && !_isExamFee(f)).toList();
    final busFees = regularFees.where((f) => _isBusFee(f)).toList();
    final tuitionFees = regularFees.where((f) => _isTuitionFee(f)).toList();
    final hostelFees = regularFees.where((f) => _isHostelFee(f)).toList();
    final examFees = regularFees.where((f) => _isExamFee(f)).toList();

    // Group term fees by term
    final Map<String, List<FeeModel>> feesByTerm = {};
    for (final fee in termFees) {
      final term = fee.demfeeterm;
      feesByTerm.putIfAbsent(term, () => []);
      feesByTerm[term]!.add(fee);
    }

    // Calculate selected amount from local selection (not cart).
    //
    // amountFor(), NOT balancedue: a part-paid fee contributes the amount the
    // parent chose, so the figure on the button is the figure that will be
    // charged. Summing balances here left the total unchanged when a part
    // amount was set -- the row said 500 while the button still said 20,125.
    final selectedFees = filteredFees.where((f) => _localSelectedFeeIds.contains(f.id)).toList();
    final selectedAmount =
        selectedFees.fold<double>(0, (sum, fee) => sum + cartState.amountFor(fee));

    // Check if term fees are selected out of order
    final sortedTermKeys = feesByTerm.keys.toList()..sort((a, b) {
      final aDate = feesByTerm[a]!.first.duedate ?? feesByTerm[a]!.first.createdat;
      final bDate = feesByTerm[b]!.first.duedate ?? feesByTerm[b]!.first.createdat;
      return aDate.compareTo(bDate);
    });
    bool hasTermOutOfOrder = false;
    for (int i = 1; i < sortedTermKeys.length; i++) {
      final currentTermFees = feesByTerm[sortedTermKeys[i]]!;
      final previousTermFees = feesByTerm[sortedTermKeys[i - 1]]!;
      final currentHasSelection = currentTermFees.any((f) => _localSelectedFeeIds.contains(f.id));
      final previousFullySelected = previousTermFees.every((f) => _localSelectedFeeIds.contains(f.id));
      if (currentHasSelection && !previousFullySelected) {
        hasTermOutOfOrder = true;
        break;
      }
    }

    return DesktopDetailScaffold(
      isNested: true,
      header: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeader(context),
          const SizedBox(height: 16),
        ],
      ),
      toolbar: BreadcrumbBar(currentLabel: _getScreenTitle()),
      body: filteredFees.isEmpty
          ? _buildEmptyState()
          : _buildContentWithFilter(context, filteredFees, arrearFees, feesByTerm, busFees, tuitionFees, hostelFees, examFees, cartState),
      bottomBar: selectedAmount > 0
          ? _buildBottomBar(context, selectedFees.length, selectedAmount, filteredFees: filteredFees, hasTermOutOfOrder: hasTermOutOfOrder)
          : null,
    );
  }

  Widget _buildDesktopGreetingBanner(
      BuildContext context, List<FeeModel> fees) {
    final count = fees.length;
    final hasPending = count > 0;
    final message = hasPending
        ? "You have $count pending ${count == 1 ? 'fee' : 'fees'} to clear."
        : "All clear! You have no pending fees.";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTitle(BuildContext context) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final firstName =
        (selectedStudent?.name)?.trim().split(' ').first ?? 'Student';
    final admissionNo = selectedStudent?.admissionNumber ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$firstName's Pending Fees",
          style: TextStyle(fontFamily: AppFonts.headingFamily, 
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryC(context),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ID $admissionNo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textHintC(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStatCards(
      BuildContext context, List<FeeModel> fees) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = fees.where((f) => f.dueDate.isBefore(today)).toList();
    final dueSoon = fees
        .where((f) =>
            !f.dueDate.isBefore(today) &&
            f.dueDate.difference(today).inDays <= 7)
        .toList();
    final totalAmount =
        fees.fold<double>(0, (sum, f) => sum + (f.balancedue));
    final overdueAmount =
        overdue.fold<double>(0, (sum, f) => sum + (f.balancedue));
    return Row(
      children: [
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Total Pending',
            value: '₹${NumberFormat('#,##,###').format(totalAmount.toInt())}',
            icon: 'wallet-3',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Overdue',
            value: '₹${NumberFormat('#,##,###').format(overdueAmount.toInt())}',
            icon: 'warning-2',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Due Soon',
            value: '${dueSoon.length}',
            icon: 'clock',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Total Items',
            value: '${fees.length}',
            icon: 'receipt-text',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardTile({
    required BuildContext context,
    required String label,
    required String value,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryC(context),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final notificationCount = ref.watch(notificationCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Back Button — amber circle + state handling
          AppIconCircleButton(
            onPressed: () => context.go(Routes.home),
            icon: SvgPicture.asset(
              'assets/icons/arrow-left.svg',
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),

          // Title
          Expanded(
            child: Text(
              _getScreenTitle(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryC(context),
              ),
            ),
          ),

          // Student chip (desktop only)
          if (context.isDesktop) ...[
            _buildStudentChip(context),
            const SizedBox(width: 12),
          ],

          // Notification Button — amber circle + badge + state handling
          AppIconCircleButton(
            onPressed: () => context.go(Routes.notifications),
            badgeCount: notificationCount,
            icon: SvgPicture.asset(
              'assets/main icons/line icons/notification.svg',
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentChip(BuildContext context) {
    final student = ref.watch(selectedStudentProvider);
    if (student == null) return const SizedBox.shrink();
    final parts = student.name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.take(2).map((p) => p[0]).join().toUpperCase();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.avatarBg,
          backgroundImage: (student.photoUrl != null && student.photoUrl!.isNotEmpty)
              ? NetworkImage(student.photoUrl!) : null,
          child: (student.photoUrl == null || student.photoUrl!.isEmpty)
              ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(width: 8),
        Text(student.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryC(context))),
      ],
    );
  }

  /// Get sub-filter options based on the current fee group type
  List<String> _getSubFilterOptions(
    Map<String, List<FeeModel>> feesByTerm,
    List<FeeModel> busFees,
    List<FeeModel> tuitionFees,
    List<FeeModel> hostelFees,
    List<FeeModel> examFees,
  ) {
    // Filter is by FEE TYPE (demfeetype): list the distinct fee types across
    // all the regular fees shown in this group.
    final all = <FeeModel>[
      ...feesByTerm.values.expand((e) => e),
      ...busFees,
      ...tuitionFees,
      ...hostelFees,
      ...examFees,
    ];
    final types = all
        .map((f) => f.demfeetype.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return types;
  }

  Widget _buildContentWithFilter(
    BuildContext context,
    List<FeeModel> filteredFees,
    List<FeeModel> arrearFees,
    Map<String, List<FeeModel>> feesByTerm,
    List<FeeModel> busFees,
    List<FeeModel> tuitionFees,
    List<FeeModel> hostelFees,
    List<FeeModel> examFees,
    CartState cartState,
  ) {
    // Get sub-filter options based on the current fee group
    final subFilterOptions = _getSubFilterOptions(feesByTerm, busFees, tuitionFees, hostelFees, examFees);

    // Regular fees for this group, optionally narrowed by the selected fee
    // type. Shown in ONE card (like the arrear card), not a card per fee type.
    final regularFees = filteredFees.where((f) => !f.isArrear).toList();
    final displayedRegular = _selectedSubFilter == null
        ? regularFees
        : regularFees.where((f) => f.demfeetype == _selectedSubFilter).toList();

    return Stack(
      children: [
        // Main content - scrollable list
        GestureDetector(
          onTap: () {
            if (_isDropdownOpen) {
              setState(() {
                _isDropdownOpen = false;
              });
            }
          },
          child: ListView(
            padding: context.isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.all(16),
            children: [
              // Dashboard-style header (desktop only)
              if (context.isDesktop) ...[
                _buildDesktopGreetingBanner(context, filteredFees),
                const SizedBox(height: 18),
                _buildDesktopTitle(context),
                const SizedBox(height: 20),
                _buildDesktopStatCards(context, filteredFees),
                const SizedBox(height: 20),
              ],

              // Arrear Fees — carried-forward dues, shown first and cleared before regular.
              if (arrearFees.isNotEmpty) ...[
                _buildArrearFeesCard(context, arrearFees, cartState),
                const SizedBox(height: 12),
              ],
              // While any arrear is outstanding, regular fees are locked.
              if (_hasArrearOutstanding()) ...[
                _buildRegularLockedNotice(context),
                const SizedBox(height: 12),
              ],

              // Regular fees — ONE card listing every fee (like the arrear card).
              // Hint (only when the card is actually selectable, i.e. not locked
              // behind outstanding arrears).
              if (displayedRegular.isNotEmpty && !_hasArrearOutstanding())
                const Padding(
                  padding:
                      EdgeInsets.only(bottom: 14, left: 2, right: 2, top: 2),
                  child: Text(
                    'Select the fees you want to pay now.',
                    style: TextStyle(fontSize: 14.5, color: AppUi.inkMuted),
                  ),
                ),
              if (displayedRegular.isNotEmpty)
                _buildRegularFeesCards(context, displayedRegular, cartState),
            ],
          ),
        ),

        // Floating dropdown overlay
        if (_isDropdownOpen)
          Positioned(
            top: 90,
            left: 16,
            right: 16,
            child: _buildFloatingDropdown(subFilterOptions, feesByTerm, busFees, tuitionFees, hostelFees),
          ),
      ],
    );
  }

  Widget _buildSubFilter(List<String> subFilterOptions) {
    // Show Clear button as active when user has selected a sub-filter or has fee selections
    final hasFilter = _selectedSubFilter != null || _localSelectedFeeIds.isNotEmpty;

    const filterLabel = 'Filter';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filterLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryC(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Dropdown
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDropdownOpen = !_isDropdownOpen;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.filterBg(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderC(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedSubFilter ?? 'ALL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryC(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppIcon(
                          _isDropdownOpen ? 'arrow-up' : 'arrow-down',
                          color: AppColors.textSecondaryC(context),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Clear Button
              GestureDetector(
                onTap: hasFilter
                    ? () {
                        final cartNotifier = ref.read(cartProvider.notifier);
                        // Remove selected fees from cart
                        for (final feeId in _localSelectedFeeIds) {
                          cartNotifier.removeFee(feeId);
                        }
                        setState(() {
                          _selectedSubFilter = null;
                          _isDropdownOpen = false;
                          _localSelectedFeeIds.clear();
                          _showCartPreview = false;
                        });
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: hasFilter ? AppColors.iconButtonBg(context) : AppColors.borderC(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      AppIcon(
                        'filter',
                        size: 18,
                        color: hasFilter ? Colors.white : AppColors.textHintC(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: hasFilter ? Colors.white : AppColors.textHintC(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get fees for a given sub-filter option
  List<FeeModel> _getFeesForSubFilterOption(
    String option,
    Map<String, List<FeeModel>> feesByTerm,
    List<FeeModel> busFees,
    List<FeeModel> tuitionFees,
    List<FeeModel> hostelFees,
  ) {
    final groupName = widget.filterGroup?.toUpperCase() ?? '';
    if (groupName.contains('SCHOOL')) {
      if (option == 'TUITION FEES') return tuitionFees;
      return feesByTerm[option] ?? [];
    } else if (groupName.contains('VAN') || groupName.contains('BUS') || groupName.contains('TRANSPORT')) {
      return busFees.where((f) {
        final date = f.duedate ?? f.createdat;
        return DateFormat('MMMM yyyy').format(date) == option;
      }).toList();
    } else if (groupName.contains('TUITION')) {
      return tuitionFees.where((f) {
        final date = f.duedate ?? f.createdat;
        return DateFormat('MMMM yyyy').format(date) == option;
      }).toList();
    } else if (groupName.contains('HOSTEL')) {
      return hostelFees.where((f) {
        final date = f.duedate ?? f.createdat;
        return DateFormat('MMMM yyyy').format(date) == option;
      }).toList();
    }
    return feesByTerm[option] ?? [];
  }

  Widget _buildFloatingDropdown(
    List<String> subFilterOptions,
    Map<String, List<FeeModel>> feesByTerm,
    List<FeeModel> busFees,
    List<FeeModel> tuitionFees,
    List<FeeModel> hostelFees,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(8),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // All option - always enabled
          _buildDropdownOption(null, 'All', true, isEnabled: true),
          // Sub-filter options (terms or months) with sequential enforcement
          ...subFilterOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            // Check if previous option's fees are fully selected
            final bool isOptionEnabled;
            if (index == 0) {
              isOptionEnabled = true;
            } else {
              final prevFees = _getFeesForSubFilterOption(
                subFilterOptions[index - 1], feesByTerm, busFees, tuitionFees, hostelFees);
              isOptionEnabled = prevFees.every((f) => _localSelectedFeeIds.contains(f.id));
            }
            return _buildDropdownOption(
              option,
              option,
              option != subFilterOptions.last,
              isEnabled: isOptionEnabled,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDropdownOption(String? option, String label, bool showDivider, {bool isEnabled = true}) {
    final isSelected = _selectedSubFilter == option;

    return Column(
      children: [
        GestureDetector(
          onTap: isEnabled ? () {
            setState(() {
              _selectedSubFilter = option;
              _isDropdownOpen = false;
            });
          } : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.transparent,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: !isEnabled
                          ? AppColors.textHintC(context)
                          : isSelected ? AppColors.primary : AppColors.textPrimaryC(context),
                    ),
                  ),
                ),
                if (isSelected)
                  const AppIcon(
                    'tick-circle',
                    size: 20,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: AppColors.borderC(context)),
      ],
    );
  }

  Widget _buildTermAccordion(
    BuildContext context,
    String term,
    List<FeeModel> fees,
    CartState cartState,
    String sectionKey, {
    bool isEnabled = true,
  }) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getFeesMonthRange(fees);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => _localSelectedFeeIds.contains(f.id));

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Clearance order first, due date second. The parent works down the list
    // in the order the fees must actually be paid, so the one they are allowed
    // to tick next is always the next one down. Ranks tie until fee types are
    // given priorities in Fee Master, and a tie falls back to due date -- the
    // order this list had before.
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final r = _rankOf(a).compareTo(_rankOf(b));
        if (r != 0) return r;
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return _FeeAccordion(
      title: term,
      subtitle: monthRange,
      totalAmount: totalAmount,
      badgeColor: badgeColor,
      badgeIcon: SvgPicture.asset(
        'assets/school Icons/book.svg',
        width: 14,
        height: 14,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
      badgeText: academicYear,
      allSelected: allSelected,
      onToggleAll: () => _toggleAllFees(fees, allSelected),
      isEnabled: isEnabled,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fee Details',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
              ),
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: AppSizes.fontSemibold,
                  color: AppColors.textPrimaryC(context),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 1,
            color: AppColors.borderC(context),
          ),
          ...sortedFees.map((fee) => _buildFeeRow(fee)),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: AppSizes.textBase,
                      fontWeight: AppSizes.fontBold,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                ),
                Text(
                  '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                  style: TextStyle(
                    fontSize: AppSizes.textLg,
                    fontWeight: AppSizes.fontBold,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFeesMonthRange(List<FeeModel> fees) {
    if (fees.isEmpty) return '';

    // Check if this is a term-based fee group (I TERM, II TERM, etc.)
    final term = fees.first.demfeeterm.toUpperCase();
    if (term.contains('I TERM') && !term.contains('II')) {
      return 'May - Oct';
    } else if (term.contains('II TERM')) {
      return 'Nov - Apr';
    }

    // For non-term fees, calculate from actual dates
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final aDate = a.duedate ?? a.createdat;
        final bDate = b.duedate ?? b.createdat;
        return aDate.compareTo(bDate);
      });

    final firstDate = sortedFees.first.duedate ?? sortedFees.first.createdat;
    final lastDate = sortedFees.last.duedate ?? sortedFees.last.createdat;

    final firstMonth = DateFormat('MMM').format(firstDate);
    final lastMonth = DateFormat('MMM').format(lastDate);

    if (firstMonth == lastMonth) {
      return firstMonth;
    }
    return '$firstMonth - $lastMonth';
  }

  Widget _buildFeeRow(FeeModel fee) {
    // Mirror the arrear-fee row: clock icon, class badge + term/year sub-label,
    // and a per-row checkbox that toggles this single fee.
    final isSelected = _localSelectedFeeIds.contains(fee.id);
    const accent = AppColors.primary;
    final subLabel = '${fee.demfeeterm} ${fee.demfeeyear}'.trim();

    return GestureDetector(
      onTap: () => _toggleSingleFee(fee, isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderC(context), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                        child: AppIcon('clock-1', size: 16, color: accent)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fee.feeTypeName.toUpperCase(),
                          style: TextStyle(
                            fontSize: AppSizes.bodyText,
                            fontWeight: AppSizes.fontMedium,
                            color: AppColors.textPrimaryC(context),
                            height: 1.47,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (fee.stuclass.trim().isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  fee.stuclass,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: accent),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                subLabel,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textHintC(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Builder(builder: (context) {
              final amount = ref.watch(cartProvider).amountFor(fee);
              final isPart = amount < fee.balancedue;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹ ${NumberFormat('#,##,###').format(amount.toInt())}',
                    style: TextStyle(
                      fontSize: AppSizes.textBase,
                      fontWeight: AppSizes.fontSemibold,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                  // What the full balance was, once a part amount is set --
                  // kept as quiet text so the figure being paid stays the
                  // prominent one.
                  if (isPart)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        'of ₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryC(context),
                        ),
                      ),
                    ),
                  // Only offered where the fee type allows a part payment, so
                  // there is no control to discover and then be refused by.
                  //
                  // A tinted pill rather than small underlined text: this is a
                  // finger target on a phone, and 11sp underlined was both hard
                  // to read and hard to hit.
                  if (_partialAllowed(fee))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Material(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _editPartAmount(fee),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            child: Text(
                              isPart ? 'Change' : 'Pay part',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderC(context),
                    width: 1.5),
              ),
              child: isSelected
                  ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// One card per real fee type (demfeetype) — replaces the old hardcoded
  /// school-category cards. Title = the actual fee type; rows reuse the shared
  /// fee-row (real fee name, due date, amount).
  Widget _buildFeeTypeCard(
      BuildContext context, String feeType, List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '';
    final totalAmount = fees.fold<double>(0, (sum, f) => sum + f.balancedue);
    final allSelected =
        fees.isNotEmpty && fees.every((f) => _localSelectedFeeIds.contains(f.id));

    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final d = f.dueDate.difference(now).inDays;
      return d >= 0 && d <= 7;
    });
    final badgeColor = hasOverdue
        ? AppColors.error
        : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Clearance order first, due date second -- as in the other fee lists.
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final r = _rankOf(a).compareTo(_rankOf(b));
        if (r != 0) return r;
        return (a.duedate ?? a.createdat).compareTo(b.duedate ?? b.createdat);
      });

    return _FeeAccordion(
      title: feeType.toUpperCase(),
      subtitle: fees.isNotEmpty ? fees.first.demfeeterm : '',
      totalAmount: totalAmount,
      badgeColor: badgeColor,
      badgeIcon: const AppIcon('receipt', size: 14, color: Colors.white),
      badgeText: academicYear,
      allSelected: allSelected,
      onToggleAll: () => _toggleAllFees(fees, allSelected),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Fee Details',
                    style: TextStyle(
                        fontSize: AppSizes.textBase,
                        fontWeight: AppSizes.fontSemibold,
                        color: AppColors.textPrimaryC(context))),
              ),
              Text('Amount',
                  style: TextStyle(
                      fontSize: AppSizes.textBase,
                      fontWeight: AppSizes.fontSemibold,
                      color: AppColors.textPrimaryC(context))),
            ],
          ),
          Container(
              margin: const EdgeInsets.only(top: 12),
              height: 1,
              color: AppColors.borderC(context)),
          ...sortedFees.map((fee) => _buildFeeRow(fee)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('TOTAL',
                      style: TextStyle(
                          fontSize: AppSizes.textBase,
                          fontWeight: AppSizes.fontBold,
                          color: AppColors.textPrimaryC(context))),
                ),
                Text('₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                    style: TextStyle(
                        fontSize: AppSizes.textLg,
                        fontWeight: AppSizes.fontBold,
                        color: AppColors.textPrimaryC(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTuitionFeesCard(BuildContext context, List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getTuitionFeesMonthRange(fees);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => _localSelectedFeeIds.contains(f.id));

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Clearance order first, due date second. The parent works down the list
    // in the order the fees must actually be paid, so the one they are allowed
    // to tick next is always the next one down. Ranks tie until fee types are
    // given priorities in Fee Master, and a tie falls back to due date -- the
    // order this list had before.
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final r = _rankOf(a).compareTo(_rankOf(b));
        if (r != 0) return r;
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return _FeeAccordion(
      title: 'TUITION FEES',
      subtitle: monthRange,
      totalAmount: totalAmount,
      badgeColor: badgeColor,
      badgeIcon: const AppIcon('book', size: 14, color: Colors.white),
      badgeText: academicYear,
      allSelected: allSelected,
      onToggleAll: () => _toggleAllFees(fees, allSelected),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fee Details',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
              ),
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: AppSizes.fontSemibold,
                  color: AppColors.textPrimaryC(context),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 1,
            color: AppColors.borderC(context),
          ),
          ...sortedFees.asMap().entries.map((entry) {
            final i = entry.key;
            final fee = entry.value;
            final isCurrentSelected = _localSelectedFeeIds.contains(fee.id);
            final canCheckRow = !isCurrentSelected && (i == 0
                || _localSelectedFeeIds.contains(sortedFees[i - 1].id));
            final noLaterRowsSelected = !sortedFees.skip(i + 1).any((f) => _localSelectedFeeIds.contains(f.id));
            final canUncheckRow = isCurrentSelected && noLaterRowsSelected;
            final isRowEnabled = canCheckRow || canUncheckRow;
            return IgnorePointer(
              ignoring: !isRowEnabled,
              child: Opacity(
                opacity: isRowEnabled ? 1.0 : 0.5,
                child: _buildTuitionFeeRow(fee, cartState),
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: AppSizes.textBase,
                      fontWeight: AppSizes.fontBold,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                ),
                Text(
                  '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                  style: TextStyle(
                    fontSize: AppSizes.textLg,
                    fontWeight: AppSizes.fontBold,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTuitionFeesMonthRange(List<FeeModel> fees) {
    if (fees.isEmpty) return '';

    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final aDate = a.duedate ?? a.createdat;
        final bDate = b.duedate ?? b.createdat;
        return aDate.compareTo(bDate);
      });

    final firstDate = sortedFees.first.duedate ?? sortedFees.first.createdat;
    final lastDate = sortedFees.last.duedate ?? sortedFees.last.createdat;

    final firstMonth = DateFormat('MMM').format(firstDate);
    final lastMonth = DateFormat('MMM').format(lastDate);

    if (firstMonth == lastMonth) {
      return firstMonth;
    }
    return '$firstMonth - $lastMonth';
  }

  Widget _buildTuitionFeeRow(FeeModel fee, CartState cartState) {
    final monthName = _extractMonthFromDate(fee);
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final isSelected = _localSelectedFeeIds.contains(fee.id);

    return GestureDetector(
      onTap: () => _toggleSingleFee(fee, isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderC(context), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Month Name with book icon
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const AppIcon(
                      'book',
                      size: 16,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName.toUpperCase(),
                          style: TextStyle(
                            fontSize: AppSizes.bodyText,
                            fontWeight: AppSizes.fontMedium,
                            color: AppColors.textPrimaryC(context),
                            height: 1.47,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            AppIcon(
                              'calendar',
                              size: 12,
                              color: isOverdue ? AppColors.error : AppColors.textHintC(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isOverdue ? AppColors.error : AppColors.textHintC(context),
                              ),
                            ),
                            if (isOverdue) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Overdue',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
              style: TextStyle(
                fontSize: AppSizes.textBase,
                fontWeight: AppSizes.fontSemibold,
                color: AppColors.textPrimaryC(context),
              ),
            ),
            const SizedBox(width: 12),
            // Individual checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderC(context),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostelFeesCard(BuildContext context, List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getHostelFeesMonthRange(fees);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => _localSelectedFeeIds.contains(f.id));

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Clearance order first, due date second. The parent works down the list
    // in the order the fees must actually be paid, so the one they are allowed
    // to tick next is always the next one down. Ranks tie until fee types are
    // given priorities in Fee Master, and a tie falls back to due date -- the
    // order this list had before.
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final r = _rankOf(a).compareTo(_rankOf(b));
        if (r != 0) return r;
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return _FeeAccordion(
      title: 'HOSTEL FEES',
      subtitle: monthRange,
      totalAmount: totalAmount,
      badgeColor: badgeColor,
      badgeIcon: const AppIcon('home-2', size: 14, color: Colors.white),
      badgeText: academicYear,
      allSelected: allSelected,
      onToggleAll: () => _toggleAllFees(fees, allSelected),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fee Details',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
              ),
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: AppSizes.fontSemibold,
                  color: AppColors.textPrimaryC(context),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 1,
            color: AppColors.borderC(context),
          ),
          ...sortedFees.asMap().entries.map((entry) {
            final i = entry.key;
            final fee = entry.value;
            final isCurrentSelected = _localSelectedFeeIds.contains(fee.id);
            final canCheckRow = !isCurrentSelected && (i == 0
                || _localSelectedFeeIds.contains(sortedFees[i - 1].id));
            final noLaterRowsSelected = !sortedFees.skip(i + 1).any((f) => _localSelectedFeeIds.contains(f.id));
            final canUncheckRow = isCurrentSelected && noLaterRowsSelected;
            final isRowEnabled = canCheckRow || canUncheckRow;
            return IgnorePointer(
              ignoring: !isRowEnabled,
              child: Opacity(
                opacity: isRowEnabled ? 1.0 : 0.5,
                child: _buildHostelFeeRow(fee, cartState),
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: AppSizes.textBase,
                      fontWeight: AppSizes.fontBold,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                ),
                Text(
                  '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                  style: TextStyle(
                    fontSize: AppSizes.textLg,
                    fontWeight: AppSizes.fontBold,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHostelFeesMonthRange(List<FeeModel> fees) {
    if (fees.isEmpty) return '';

    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final aDate = a.duedate ?? a.createdat;
        final bDate = b.duedate ?? b.createdat;
        return aDate.compareTo(bDate);
      });

    final firstDate = sortedFees.first.duedate ?? sortedFees.first.createdat;
    final lastDate = sortedFees.last.duedate ?? sortedFees.last.createdat;

    final firstMonth = DateFormat('MMM').format(firstDate);
    final lastMonth = DateFormat('MMM').format(lastDate);

    if (firstMonth == lastMonth) {
      return firstMonth;
    }
    return '$firstMonth - $lastMonth';
  }

  Widget _buildHostelFeeRow(FeeModel fee, CartState cartState) {
    final monthName = _extractMonthFromDate(fee);
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final isSelected = _localSelectedFeeIds.contains(fee.id);

    return GestureDetector(
      onTap: () => _toggleSingleFee(fee, isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderC(context), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Month Name with hotel icon
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F6B63).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const AppIcon(
                      'home-2',
                      size: 16,
                      color: Color(0xFF0F6B63),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName.toUpperCase(),
                          style: TextStyle(
                            fontSize: AppSizes.bodyText,
                            fontWeight: AppSizes.fontMedium,
                            color: AppColors.textPrimaryC(context),
                            height: 1.47,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            AppIcon(
                              'calendar',
                              size: 12,
                              color: isOverdue ? AppColors.error : AppColors.textHintC(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isOverdue ? AppColors.error : AppColors.textHintC(context),
                              ),
                            ),
                            if (isOverdue) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Overdue',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
              style: TextStyle(
                fontSize: AppSizes.textBase,
                fontWeight: AppSizes.fontSemibold,
                color: AppColors.textPrimaryC(context),
              ),
            ),
            const SizedBox(width: 12),
            // Individual checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderC(context),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Arrear Fees section — carried-forward dues grouped by their original class.
  /// Freely selectable (no term gating); regular fees stay locked until these
  /// are cleared (see _shouldBlockFee / _hasArrearOutstanding).
  /// Arrear Fees — a SEPARATE card per arrear year (each year = one receipt),
  /// with a single common note above them all.
  Widget _buildArrearFeesCard(BuildContext context, List<FeeModel> allArrear, CartState cartState) {
    final style = FeeGroupUtils.arrearStyle;
    final accent = style['color'] as Color;
    final years = <String>{
      for (final f in allArrear)
        if (f.demfeeyear.trim().isNotEmpty) f.demfeeyear.trim()
    }.toList()
      ..sort();

    final cards = <Widget>[];
    if (years.isEmpty) {
      cards.add(_buildArrearYearCard(context, '', allArrear, cartState, allArrear));
    } else {
      for (var i = 0; i < years.length; i++) {
        cards.add(_buildArrearYearCard(
          context,
          years[i],
          allArrear.where((f) => f.demfeeyear.trim() == years[i]).toList(),
          cartState,
          allArrear,
        ));
        if (i < years.length - 1) cards.add(const SizedBox(height: 12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Common note for every arrear year (shown once, not per card).
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
          child: Row(
            children: [
              AppIcon('tick-circle', size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Select single or multiple fees to pay',
                    style: TextStyle(
                        fontSize: AppSizes.textSm,
                        fontWeight: AppSizes.fontSemibold,
                        color: accent)),
              ),
            ],
          ),
        ),
        ...cards,
      ],
    );
  }

  /// One arrear-year card: that year's carried-forward dues grouped by the
  /// class they came from, with its own total. Each year is paid separately.
  Widget _buildArrearYearCard(BuildContext context, String year,
      List<FeeModel> fees, CartState cartState, List<FeeModel> allArrear) {
    final style = FeeGroupUtils.arrearStyle;
    final accent = style['color'] as Color;
    final totalAmount =
        fees.fold<double>(0, (sum, fee) => sum + cartState.amountFor(fee));
    final allSelected =
        fees.isNotEmpty && fees.every((f) => _localSelectedFeeIds.contains(f.id));

    // Group arrear demands by the class they were carried forward from.
    final Map<String, List<FeeModel>> byClass = {};
    for (final f in fees) {
      final k = f.arrearClassLabel.isNotEmpty ? f.arrearClassLabel : 'Arrear';
      byClass.putIfAbsent(k, () => []).add(f);
    }
    final classes = byClass.keys.toList()..sort();

    return _FeeAccordion(
      title: 'ARREAR FEES',
      subtitle: '',
      totalAmount: totalAmount,
      badgeColor: style['badgeColor'] as Color,
      badgeIcon: AppIcon(style['icon'] as String, size: 14, color: Colors.white),
      badgeText: year.isNotEmpty ? year : 'Arrear',
      allSelected: allSelected,
      // Only ONE arrear year at a time: selecting this card clears other years.
      onToggleAll: () => _toggleArrearYear(fees, allArrear, allSelected),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Fee Details',
                    style: TextStyle(fontSize: AppSizes.textBase, fontWeight: AppSizes.fontSemibold, color: AppColors.textPrimaryC(context))),
              ),
              Text('Amount',
                  style: TextStyle(fontSize: AppSizes.textBase, fontWeight: AppSizes.fontSemibold, color: AppColors.textPrimaryC(context))),
              const SizedBox(width: 36),
            ],
          ),
          Container(margin: const EdgeInsets.only(top: 12), height: 1, color: AppColors.borderC(context)),
          for (final cls in classes) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Row(
                children: [
                  AppIcon(style['icon'] as String, size: 13, color: accent),
                  const SizedBox(width: 6),
                  Text('From: $cls',
                      style: TextStyle(fontSize: AppSizes.textBase, fontWeight: AppSizes.fontSemibold, color: accent)),
                ],
              ),
            ),
            ..._termSections(context, byClass[cls]!,
                (f) => _buildArrearFeeRow(f, cartState, allArrear)),
          ],
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('TOTAL',
                      style: TextStyle(fontSize: AppSizes.textBase, fontWeight: AppSizes.fontBold, color: AppColors.textPrimaryC(context))),
                ),
                Text('₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                    style: TextStyle(fontSize: AppSizes.textLg, fontWeight: AppSizes.fontBold, color: AppColors.textPrimaryC(context))),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// All regular (non-arrear) fees for this group in ONE card — mirrors the
  /// single Arrear Fees card (one accordion listing every fee row + a TOTAL)
  /// instead of a separate card per fee type.
  /// A separate card per semester, rather than one card with sections inside.
  /// Each instalment then carries its own total and its own select-all, so a
  /// parent paying "IV SEM" ticks one card. Ordered by the rank of each term's
  /// earliest-clearing fee, so the term to settle first is on top.
  ///
  /// The priority rule still spans cards -- it is per student, not per card --
  /// so ticking a later term can still be refused until an earlier term's
  /// blocking fee is ticked.
  Widget _buildRegularFeesCards(
      BuildContext context, List<FeeModel> fees, CartState cartState) {
    final sections = _byTerm(fees);
    final cards = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      cards.add(_buildRegularFeesCard(context, sections[i].value, cartState,
          termLabel: sections[i].key));
      if (i < sections.length - 1) cards.add(const SizedBox(height: 12));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: cards);
  }

  Widget _buildRegularFeesCard(
      BuildContext context, List<FeeModel> fees, CartState cartState,
      {String termLabel = ''}) {
    // Chosen amounts, so the card header and its TOTAL row agree with the rows
    // above them.
    final totalAmount =
        fees.fold<double>(0, (sum, f) => sum + cartState.amountFor(f));
    final allSelected =
        fees.isNotEmpty && fees.every((f) => _localSelectedFeeIds.contains(f.id));
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '';
    // The semester IS the card's identity now that there is one card per term.
    // Every card would otherwise read "COLLEGE FEES", with the only thing that
    // tells them apart demoted to the subtitle. Falls back to the fee-group
    // name for a card that carries no term at all.
    final groupTitle = (widget.filterGroup?.trim().isNotEmpty ?? false)
        ? widget.filterGroup!.toUpperCase()
        : 'COLLEGE FEES';
    final title =
        termLabel.trim().isEmpty ? groupTitle : termLabel.toUpperCase();

    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final d = f.dueDate.difference(now).inDays;
      return d >= 0 && d <= 7;
    });
    final badgeColor = hasOverdue
        ? AppColors.error
        : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Group by class (like the arrear card's "From: <class>" sections), then by
    // semester inside each class. Rows order by CLEARANCE RANK -- this list is
    // the one the parent ticks down, so it has to agree with what the rule will
    // actually allow. Fee-type name is only the tie-break, which is what this
    // sorted by before.
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final r = _rankOf(a).compareTo(_rankOf(b));
        if (r != 0) return r;
        final c = a.demfeetype.compareTo(b.demfeetype);
        return c != 0 ? c : a.demfeeterm.compareTo(b.demfeeterm);
      });
    final byClass = <String, List<FeeModel>>{};
    for (final f in sortedFees) {
      final k = f.stuclass.trim().isNotEmpty ? f.stuclass.trim() : 'Fees';
      byClass.putIfAbsent(k, () => []).add(f);
    }
    final classes = byClass.keys.toList()..sort();

    return _FeeAccordion(
      title: title,
      // Nothing here: the term moved up into the title, and repeating the fee
      // group on every card adds a line without adding information.
      subtitle: '',
      totalAmount: totalAmount,
      badgeColor: badgeColor,
      badgeIcon: const AppIcon('receipt', size: 14, color: Colors.white),
      badgeText: academicYear,
      allSelected: allSelected,
      onToggleAll: () => _toggleAllFees(fees, allSelected),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Fee Details',
                    style: TextStyle(
                        fontSize: AppSizes.textBase,
                        fontWeight: AppSizes.fontSemibold,
                        color: AppColors.textPrimaryC(context))),
              ),
              Text('Amount',
                  style: TextStyle(
                      fontSize: AppSizes.textBase,
                      fontWeight: AppSizes.fontSemibold,
                      color: AppColors.textPrimaryC(context))),
              const SizedBox(width: 36),
            ],
          ),
          Container(
              margin: const EdgeInsets.only(top: 12),
              height: 1,
              color: AppColors.borderC(context)),
          for (final cls in classes) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Row(
                children: [
                  const AppIcon('receipt', size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('From: $cls',
                      style: TextStyle(
                          fontSize: AppSizes.textBase,
                          fontWeight: AppSizes.fontSemibold,
                          color: AppColors.primary)),
                ],
              ),
            ),
            ..._termSections(context, byClass[cls]!, _buildFeeRow),
          ],
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('TOTAL',
                      style: TextStyle(
                          fontSize: AppSizes.textBase,
                          fontWeight: AppSizes.fontBold,
                          color: AppColors.textPrimaryC(context))),
                ),
                Text('₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                    style: TextStyle(
                        fontSize: AppSizes.textLg,
                        fontWeight: AppSizes.fontBold,
                        color: AppColors.textPrimaryC(context))),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularLockedNotice(BuildContext context) {
    final accent = FeeGroupUtils.arrearStyle['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AppIcon('warning-2', size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Regular fees are locked until all arrear dues are cleared.',
              style: TextStyle(fontSize: AppSizes.bodyText, fontWeight: AppSizes.fontMedium, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrearFeeRow(FeeModel fee, CartState cartState, List<FeeModel> allArrear) {
    final isSelected = _localSelectedFeeIds.contains(fee.id);
    final accent = FeeGroupUtils.arrearStyle['color'] as Color;

    return GestureDetector(
      // Selecting an arrear row scopes to its year (clears other-year arrears).
      onTap: () => _toggleSingleArrear(fee, allArrear, isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderC(context), width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Center(child: AppIcon('clock-1', size: 16, color: accent)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fee.demfeetype.toUpperCase(),
                            style: TextStyle(fontSize: AppSizes.bodyText, fontWeight: AppSizes.fontMedium, color: AppColors.textPrimaryC(context), height: 1.47)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (fee.arrearClassLabel.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(fee.arrearClassLabel,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text('${fee.demfeeterm} ${fee.demfeeyear}'.trim(),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textHintC(context))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Builder(builder: (context) {
              final amount = ref.watch(cartProvider).amountFor(fee);
              final isPart = amount < fee.balancedue;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹ ${NumberFormat('#,##,###').format(amount.toInt())}',
                    style: TextStyle(
                      fontSize: AppSizes.textBase,
                      fontWeight: AppSizes.fontSemibold,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                  // What the full balance was, once a part amount is set --
                  // kept as quiet text so the figure being paid stays the
                  // prominent one.
                  if (isPart)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        'of ₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryC(context),
                        ),
                      ),
                    ),
                  // Only offered where the fee type allows a part payment, so
                  // there is no control to discover and then be refused by.
                  //
                  // A tinted pill rather than small underlined text: this is a
                  // finger target on a phone, and 11sp underlined was both hard
                  // to read and hard to hit.
                  if (_partialAllowed(fee))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Material(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _editPartAmount(fee),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            child: Text(
                              isPart ? 'Change' : 'Pay part',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderC(context), width: 1.5),
              ),
              child: isSelected ? const AppIcon('tick-circle', size: 16, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamFeesCard(BuildContext context, List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => _localSelectedFeeIds.contains(f.id));

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Clearance order first, due date second. The parent works down the list
    // in the order the fees must actually be paid, so the one they are allowed
    // to tick next is always the next one down. Ranks tie until fee types are
    // given priorities in Fee Master, and a tie falls back to due date -- the
    // order this list had before.
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final r = _rankOf(a).compareTo(_rankOf(b));
        if (r != 0) return r;
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return _FeeAccordion(
      title: 'EXAM FEES',
      subtitle: '',
      totalAmount: totalAmount,
      badgeColor: badgeColor,
      badgeIcon: SvgPicture.asset(
        'assets/school Icons/exam.svg',
        width: 14,
        height: 14,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
      badgeText: academicYear,
      allSelected: allSelected,
      onToggleAll: () => _toggleAllFees(fees, allSelected),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fee Details',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
              ),
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: AppSizes.fontSemibold,
                  color: AppColors.textPrimaryC(context),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 1,
            color: AppColors.borderC(context),
          ),
          ...sortedFees.asMap().entries.map((entry) {
            final i = entry.key;
            final fee = entry.value;
            final isCurrentSelected = _localSelectedFeeIds.contains(fee.id);
            final canCheckRow = !isCurrentSelected && (i == 0
                || _localSelectedFeeIds.contains(sortedFees[i - 1].id));
            final noLaterRowsSelected = !sortedFees.skip(i + 1).any((f) => _localSelectedFeeIds.contains(f.id));
            final canUncheckRow = isCurrentSelected && noLaterRowsSelected;
            final isRowEnabled = canCheckRow || canUncheckRow;
            return IgnorePointer(
              ignoring: !isRowEnabled,
              child: Opacity(
                opacity: isRowEnabled ? 1.0 : 0.5,
                child: _buildExamFeeRow(fee, cartState),
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: AppSizes.textBase,
                      fontWeight: AppSizes.fontBold,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                ),
                Text(
                  '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                  style: TextStyle(
                    fontSize: AppSizes.textLg,
                    fontWeight: AppSizes.fontBold,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamFeeRow(FeeModel fee, CartState cartState) {
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final isSelected = _localSelectedFeeIds.contains(fee.id);

    return GestureDetector(
      onTap: () => _toggleSingleFee(fee, isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderC(context), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fee name with exam icon
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F7FB5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/school Icons/exam.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF2F7FB5),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fee.demfeetype.toUpperCase(),
                          style: TextStyle(
                            fontSize: AppSizes.bodyText,
                            fontWeight: AppSizes.fontMedium,
                            color: AppColors.textPrimaryC(context),
                            height: 1.47,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            AppIcon(
                              'calendar',
                              size: 12,
                              color: isOverdue ? AppColors.error : AppColors.textHintC(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isOverdue ? AppColors.error : AppColors.textHintC(context),
                              ),
                            ),
                            if (isOverdue) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Overdue',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
              style: TextStyle(
                fontSize: AppSizes.textBase,
                fontWeight: AppSizes.fontSemibold,
                color: AppColors.textPrimaryC(context),
              ),
            ),
            const SizedBox(width: 12),
            // Individual checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderC(context),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusFeesCard(BuildContext context, List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getBusFeesMonthRange(fees);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => _localSelectedFeeIds.contains(f.id));

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Clearance order first, due date second. The parent works down the list
    // in the order the fees must actually be paid, so the one they are allowed
    // to tick next is always the next one down. Ranks tie until fee types are
    // given priorities in Fee Master, and a tie falls back to due date -- the
    // order this list had before.
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final r = _rankOf(a).compareTo(_rankOf(b));
        if (r != 0) return r;
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return _FeeAccordion(
      title: 'VAN FEES',
      subtitle: monthRange,
      totalAmount: totalAmount,
      badgeColor: badgeColor,
      badgeIcon: const AppIcon('bus', size: 14, color: Colors.white),
      badgeText: academicYear,
      allSelected: allSelected,
      onToggleAll: () => _toggleAllFees(fees, allSelected),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fee Details',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
              ),
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: AppSizes.fontSemibold,
                  color: AppColors.textPrimaryC(context),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 1,
            color: AppColors.borderC(context),
          ),
          ...sortedFees.asMap().entries.map((entry) {
            final i = entry.key;
            final fee = entry.value;
            final isCurrentSelected = _localSelectedFeeIds.contains(fee.id);
            final canCheckRow = !isCurrentSelected && (i == 0
                || _localSelectedFeeIds.contains(sortedFees[i - 1].id));
            final noLaterRowsSelected = !sortedFees.skip(i + 1).any((f) => _localSelectedFeeIds.contains(f.id));
            final canUncheckRow = isCurrentSelected && noLaterRowsSelected;
            final isRowEnabled = canCheckRow || canUncheckRow;
            return IgnorePointer(
              ignoring: !isRowEnabled,
              child: Opacity(
                opacity: isRowEnabled ? 1.0 : 0.5,
                child: _buildBusFeeRow(fee, cartState),
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: AppSizes.textBase,
                      fontWeight: AppSizes.fontBold,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                ),
                Text(
                  '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                  style: TextStyle(
                    fontSize: AppSizes.textLg,
                    fontWeight: AppSizes.fontBold,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBusFeesMonthRange(List<FeeModel> fees) {
    if (fees.isEmpty) return '';

    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final aDate = a.duedate ?? a.createdat;
        final bDate = b.duedate ?? b.createdat;
        return aDate.compareTo(bDate);
      });

    final firstDate = sortedFees.first.duedate ?? sortedFees.first.createdat;
    final lastDate = sortedFees.last.duedate ?? sortedFees.last.createdat;

    final firstMonth = DateFormat('MMM').format(firstDate);
    final lastMonth = DateFormat('MMM').format(lastDate);

    if (firstMonth == lastMonth) {
      return firstMonth;
    }
    return '$firstMonth - $lastMonth';
  }

  Widget _buildBusFeeRow(FeeModel fee, CartState cartState) {
    final monthName = _extractMonthFromDate(fee);
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final isSelected = _localSelectedFeeIds.contains(fee.id);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderC(context), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Month Name with bus icon
          Expanded(
            child: Row(
              children: [
                const AppIcon(
                  'bus',
                  size: 16,
                  color: Color(0xFFF0A43A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthName.toUpperCase(),
                        style: TextStyle(
                          fontSize: AppSizes.bodyText,
                          fontWeight: AppSizes.fontMedium,
                          color: AppColors.textPrimaryC(context),
                          height: 1.47,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AppIcon(
                            'calendar',
                            size: 12,
                            color: isOverdue ? AppColors.error : AppColors.textHintC(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isOverdue ? AppColors.error : AppColors.textHintC(context),
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Overdue',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
            style: TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: AppSizes.fontSemibold,
              color: AppColors.textPrimaryC(context),
            ),
          ),
          const SizedBox(width: 12),
          // Individual checkbox — only the checkbox is tappable
          GestureDetector(
            onTap: () => _toggleSingleFee(fee, isSelected),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderC(context),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int selectedCount, double selectedAmount, {required List<FeeModel> filteredFees, bool hasTermOutOfOrder = false}) {
    final cartState = ref.watch(cartProvider);
    final groupIcons = _getUniqueGroupIcons(cartState.items);

    final bottomContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cart preview bar — only shown after "Add to Cart" is clicked
        if (_showCartPreview && cartState.isNotEmpty)
          GestureDetector(
            onTap: () => context.push(Routes.cart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderC(context), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Queue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        ...groupIcons.take(4).map((icon) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: icon['bgColor'] as Color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: icon['iconData'] != null
                                  ? AppIcon(
                                      icon['iconData'] as String,
                                      size: 16,
                                      color: icon['iconColor'] as Color,
                                    )
                                  : SvgPicture.asset(
                                      icon['svgPath'] as String,
                                      width: 16,
                                      height: 16,
                                      colorFilter: ColorFilter.mode(
                                        icon['iconColor'] as Color,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: groupIcons.isNotEmpty
                          ? groupIcons[0]['bgColor'] as Color
                          : const Color(0xFFFDF0DA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${cartState.itemCount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: groupIcons.isNotEmpty
                              ? groupIcons[0]['iconColor'] as Color
                              : const Color(0xFFF0A43A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Bottom action row
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$selectedCount fee${selectedCount > 1 ? 's' : ''} selected',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryC(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${NumberFormat('#,##,###').format(selectedAmount.toInt())}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryC(context),
                      letterSpacing: -0.6,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              // Button changes based on state
              if (_showCartPreview)
                AppActionButton(
                  onPressed: () => context.push(Routes.cart),
                  label: 'View list',
                  borderRadius: 12,
                  fullWidth: false,
                  horizontalPadding: 28,
                  trailing: const AppIcon(
                    'arrow-right-1',
                    size: 20,
                    color: Colors.white,
                  ),
                )
              else
                AppActionButton(
                  onPressed: (selectedAmount > 0 && !hasTermOutOfOrder)
                      ? () {
                          if (_addSelectedFeesToCart(filteredFees)) {
                            setState(() => _showCartPreview = true);
                          }
                        }
                      : null,
                  label: 'Add to queue',
                  borderRadius: 12,
                  fullWidth: false,
                  horizontalPadding: 28,
                  leading: const AppIcon(
                    'shopping-cart',
                    size: 20,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    // On desktop, DesktopDetailScaffold wraps in a card — return just the inner content
    if (context.isDesktop) return bottomContent;

    // On mobile, keep existing decoration
    return Container(
      decoration: const BoxDecoration(
        color: AppUi.card,
        border: Border(top: BorderSide(color: AppUi.line)),
      ),
      child: SafeArea(
        top: false,
        child: bottomContent,
      ),
    );
  }

  List<Map<String, dynamic>> _getUniqueGroupIcons(List<FeeModel> items) {
    final seen = <String>{};
    final icons = <Map<String, dynamic>>[];
    for (final fee in items) {
      final type = fee.demfeetype.toLowerCase();
      String groupKey;
      String svgPath;
      Color bgColor;
      Color iconColor;
      if (type.contains('bus') || type.contains('transport') || type.contains('van')) {
        groupKey = 'van';
        svgPath = 'assets/school Icons/van.svg';
        bgColor = const Color(0xFFFDF0DA);
        iconColor = const Color(0xFFF0A43A);
      } else if (type.contains('hostel')) {
        groupKey = 'hostel';
        svgPath = '';
        bgColor = const Color(0xFF0F6B63).withValues(alpha: 0.1);
        iconColor = const Color(0xFF0F6B63);
      } else if (type.contains('exam')) {
        groupKey = 'exam';
        svgPath = 'assets/school Icons/exam.svg';
        bgColor = const Color(0xFF2F7FB5).withValues(alpha: 0.1);
        iconColor = const Color(0xFF2F7FB5);
      } else {
        groupKey = 'school';
        svgPath = 'assets/school Icons/school.svg';
        bgColor = const Color(0xFFE1F0EC);
        iconColor = const Color(0xFF0F6B63);
      }
      if (!seen.contains(groupKey)) {
        seen.add(groupKey);
        icons.add({
          'svgPath': svgPath,
          'bgColor': bgColor,
          'iconColor': iconColor,
          'iconData': groupKey == 'hostel' ? 'home-2' : (groupKey == 'van' ? 'bus' : null),
        });
      }
    }
    return icons;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: const AppIcon(
                'tick-circle',
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.filterStatus == 'dueSoon'
                  ? 'No Upcoming Fees'
                  : widget.filterStatus == 'overdue'
                      ? 'No Overdue Fees'
                      : 'No Pending Fees',
              style: TextStyle(
                fontSize: AppSizes.textLg,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryC(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.filterStatus == 'dueSoon'
                  ? 'There are no fees due at this time. We will notify you when a new fee is posted.'
                  : widget.filterStatus == 'overdue'
                      ? 'Great! You have no overdue fees.'
                      : 'All your fees are paid. Great job!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.textSm,
                color: AppColors.textSecondaryC(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  /// Check if selection should be blocked (dueSoon view with overdue fees pending)
  // Returns true if there are overdue fees that must be settled first
  bool _hasOverdueFees() {
    final pendingFees = ref.read(pendingFeesProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return pendingFees.any((f) => f.dueDate.isBefore(today));
  }

  // Arrear-first: any unpaid arrear demand outstanding for this student.
  bool _hasArrearOutstanding() {
    return ref.read(pendingFeesProvider).any((f) => f.isArrear);
  }

  // Block selection of a fee if (a) it is regular while arrear is still
  // outstanding (arrear-first), or (b) it is not overdue but overdue fees exist.
  bool _shouldBlockFee(FeeModel fee) {
    if (!fee.isArrear && _hasArrearOutstanding()) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final feeIsOverdue = fee.dueDate.isBefore(today);
    if (feeIsOverdue) return false; // Always allow selecting overdue fees
    return _hasOverdueFees();
  }

  bool _shouldBlockSelection() {
    if (widget.filterStatus != 'dueSoon') return false;
    return _hasOverdueFees();
  }

  void _showOverdueBlockMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            AppIcon('warning-2', color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Please pay overdue fees first before selecting upcoming fees.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Names what is holding a fee up. The server returns the fee types, so the
  /// parent is told what to pay first rather than just being refused.
  void _showPriorityBlockMessage(String blockedBy) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const AppIcon('warning-2', color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Clear $blockedBy first.',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showArrearBlockMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            AppIcon('warning-2', color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Clear the arrear dues first before paying regular fees.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleAllFees(List<FeeModel> fees, bool allSelected) {
    if (!allSelected) {
      // Payment order, as configured per fee type in the admin app (bus first,
      // exam last, arrears before current-year fees). Checked before the older
      // hard-coded rules below so the message names the ACTUAL blocker rather
      // than a generic one.
      // The whole batch counts as selected while checking, so a group holding
      // both a fee and the fee ranked below it selects cleanly -- only blockers
      // OUTSIDE the batch can hold it up.
      final batch = fees.map((f) => f.id).toSet();
      for (final f in fees) {
        final blockers = _unmetBlockers(f, alsoSelected: batch);
        if (blockers.isNotEmpty) {
          _showPriorityBlockMessage(blockers.join(', '));
          return;
        }
      }
      // Arrear-first: block selecting a group of regular fees while arrear is unpaid.
      if (fees.any((f) => !f.isArrear) && _hasArrearOutstanding()) {
        _showArrearBlockMessage();
        return;
      }
      // Block adding upcoming fees when overdue fees exist
      if (_shouldBlockSelection()) {
        _showOverdueBlockMessage();
        return;
      }
    } else {
      final stranded = _strandedBy(fees.map((f) => f.id).toSet());
      if (stranded.isNotEmpty) {
        _showPriorityRemoveMessage(stranded);
        return;
      }
    }
    final cartNotifier = ref.read(cartProvider.notifier);
    setState(() {
      if (allSelected) {
        for (final fee in fees) {
          _localSelectedFeeIds.remove(fee.id);
          // Also remove from cart if already added
          cartNotifier.removeFee(fee.id);
        }
      } else {
        for (final fee in fees) {
          _localSelectedFeeIds.add(fee.id);
        }
      }
    });
    // The batch's LAST-clearing fee is the one that constrains the rest.
    if (!allSelected && fees.isNotEmpty) {
      _resetPartAmountsBelow(
          fees.map(_rankOf).reduce((a, b) => a > b ? a : b));
    }
  }

  /// Select/deselect a whole arrear YEAR card, enforcing one year at a time:
  /// selecting this year first clears every other arrear year's selection.
  void _toggleArrearYear(
      List<FeeModel> yearFees, List<FeeModel> allArrear, bool allSelected) {
    final cartNotifier = ref.read(cartProvider.notifier);
    setState(() {
      if (allSelected) {
        for (final f in yearFees) {
          _localSelectedFeeIds.remove(f.id);
          cartNotifier.removeFee(f.id);
        }
      } else {
        // Clear ALL arrear selections (every year), then select this year's.
        for (final f in allArrear) {
          _localSelectedFeeIds.remove(f.id);
          cartNotifier.removeFee(f.id);
        }
        for (final f in yearFees) {
          _localSelectedFeeIds.add(f.id);
        }
      }
    });
  }

  /// Select/deselect a single arrear fee, scoped to its year: selecting it
  /// clears any arrear selections from other years (one year at a time).
  /// Arrears are ranked among themselves too -- an arrear bus fee outranks an
  /// arrear tuition fee -- so this path needs the same gate.
  void _toggleSingleArrear(
      FeeModel fee, List<FeeModel> allArrear, bool isSelected) {
    if (!isSelected) {
      final blockers = _unmetBlockers(fee);
      if (blockers.isNotEmpty) {
        _showPriorityBlockMessage(blockers.join(', '));
        return;
      }
    } else {
      final stranded = _strandedBy({fee.id});
      if (stranded.isNotEmpty) {
        _showPriorityRemoveMessage(stranded);
        return;
      }
    }
    final cartNotifier = ref.read(cartProvider.notifier);
    setState(() {
      if (isSelected) {
        _localSelectedFeeIds.remove(fee.id);
        cartNotifier.removeFee(fee.id);
      } else {
        final year = fee.demfeeyear.trim();
        for (final f in allArrear.where((a) => a.demfeeyear.trim() != year)) {
          _localSelectedFeeIds.remove(f.id);
          cartNotifier.removeFee(f.id);
        }
        _localSelectedFeeIds.add(fee.id);
      }
    });
    if (!isSelected) _resetPartAmountsBelow(_rankOf(fee));
  }

  void _toggleSingleFee(FeeModel fee, bool isSelected) {
    // Payment order, from the per-fee-type configuration. Checked first so the
    // message names the actual blocker. Selecting a single row has to go
    // through the same gate as the group toggle, or the rule is enforced on
    // "select all" and bypassed by ticking one box.
    if (!isSelected) {
      final blockers = _unmetBlockers(fee);
      if (blockers.isNotEmpty) {
        _showPriorityBlockMessage(blockers.join(', '));
        return;
      }
    } else {
      // Removing a fee that a later one is riding on would leave a selection
      // the server refuses -- after the gateway is already open.
      final stranded = _strandedBy({fee.id});
      if (stranded.isNotEmpty) {
        _showPriorityRemoveMessage(stranded);
        return;
      }
    }
    // Arrear-first: block regular fees while arrear is outstanding (distinct message).
    if (!isSelected && !fee.isArrear && _hasArrearOutstanding()) {
      _showArrearBlockMessage();
      return;
    }
    // Block adding upcoming/due-today fees when overdue fees exist
    if (!isSelected && _shouldBlockFee(fee)) {
      _showOverdueBlockMessage();
      return;
    }
    final cartNotifier = ref.read(cartProvider.notifier);
    setState(() {
      if (isSelected) {
        _localSelectedFeeIds.remove(fee.id);
        // Also remove from cart if already added
        cartNotifier.removeFee(fee.id);
      } else {
        _localSelectedFeeIds.add(fee.id);
      }
    });
    // Anything ranked before this one must now be paid in full.
    if (!isSelected) _resetPartAmountsBelow(_rankOf(fee));
  }

  /// Add all locally selected fees to the cart
  /// Adds the locally-selected fees to the cart. Returns false (and shows a
  /// message) without adding when it would mix fee YEARS — the cart may only
  /// hold one year at a time so each year (esp. arrears) is paid on its own
  /// receipt.
  bool _addSelectedFeesToCart(List<FeeModel> allFees) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartState = ref.read(cartProvider);
    final feesToAdd =
        allFees.where((f) => _localSelectedFeeIds.contains(f.id)).toList();
    if (feesToAdd.isEmpty) return false;

    final existingYears = cartState.items
        .map((f) => f.demfeeyear.trim())
        .where((y) => y.isNotEmpty)
        .toSet();
    final addYears = feesToAdd
        .map((f) => f.demfeeyear.trim())
        .where((y) => y.isNotEmpty)
        .toSet();
    if ({...existingYears, ...addYears}.length > 1) {
      final msg = existingYears.isNotEmpty
          ? 'Your queue already has ${existingYears.first} fees. Pay or clear those first before adding another year.'
          : 'Please select fees from one year only — you can pay each year separately.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const AppIcon('warning-2', color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
      return false;
    }

    final refused = cartNotifier.addFees(feesToAdd);
    if (refused > 0) {
      final note = ref.read(cartProvider).blockedNote;
      if (note != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(note),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    return true;
  }

  String _extractMonthFromDate(FeeModel fee) {
    final date = fee.duedate ?? fee.createdat;
    return DateFormat('MMMM yyyy').format(date);
  }

  String _getScreenTitle() {
    String title = '';

    // Add status prefix
    if (widget.filterStatus == 'overdue') {
      title = 'Overdue';
    } else if (widget.filterStatus == 'dueSoon') {
      title = 'Upcoming';
    }

    // Add group name
    if (widget.filterGroup != null) {
      if (title.isNotEmpty) {
        title += ' ${_toTitleCase(widget.filterGroup!)}';
      } else {
        title = '${_toTitleCase(widget.filterGroup!)} Details';
      }
    } else if (title.isEmpty) {
      title = 'All Pending Fees';
    } else {
      title += ' Fees';
    }

    return title;
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Reusable accordion widget for collapsible fee cards.
class _FeeAccordion extends StatefulWidget {
  final String title;
  final String subtitle;
  final double totalAmount;
  final Color badgeColor;
  final Widget badgeIcon;
  final String badgeText;
  final bool allSelected;
  final VoidCallback onToggleAll;
  final bool isEnabled;
  final Widget content;
  // Flat mode: a single tappable row (name + semester, amount) that toggles
  // selection — no year badge, no checkbox, no chevron, no expandable detail.
  final bool flat;

  const _FeeAccordion({
    required this.title,
    required this.subtitle,
    required this.totalAmount,
    required this.badgeColor,
    required this.badgeIcon,
    required this.badgeText,
    required this.allSelected,
    required this.onToggleAll,
    this.isEnabled = true,
    required this.content,
    this.flat = false,
  });

  @override
  State<_FeeAccordion> createState() => _FeeAccordionState();
}

class _FeeAccordionState extends State<_FeeAccordion>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.isEnabled,
      child: Opacity(
        opacity: widget.isEnabled ? 1.0 : 0.6,
        child: Container(
          // Selection is carried by the border and a faint wash, in every mode
          // -- not only the flat one. A card the parent has ticked should look
          // ticked whether or not it happens to be expandable.
          decoration: BoxDecoration(
            color: widget.allSelected
                ? AppUi.link.withValues(alpha: 0.05)
                : AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: widget.allSelected ? AppUi.link : AppUi.line,
                width: widget.allSelected ? 1.5 : 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.flat ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row — flat: tap selects; otherwise tap expands/collapses.
                GestureDetector(
                  onTap: widget.flat ? widget.onToggleAll : _toggle,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryC(context),
                              ),
                            ),
                            // Year pill sits under the title so the title always
                            // gets the full row width on one line.
                            if (!widget.flat && widget.badgeText.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.badgeColor
                                      .withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                          widget.badgeColor, BlendMode.srcIn),
                                      child: widget.badgeIcon,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      widget.badgeText,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: widget.badgeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (widget.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondaryC(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Total amount in collapsed state
                      Text(
                        '₹${NumberFormat('#,##,###').format(widget.totalAmount.toInt())}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryC(context),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      // Flat mode drops the badge, checkbox and chevron; a small
                      // tick just marks the row as selected.
                      if (widget.flat && widget.allSelected) ...[
                        const SizedBox(width: 10),
                        const AppIcon('tick-circle', size: 20, color: AppColors.primary),
                      ],
                      if (!widget.flat) ...[
                        const SizedBox(width: 10),
                        // Checkbox — separate tap target
                        GestureDetector(
                          onTap: widget.onToggleAll,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: widget.allSelected
                                  ? AppUi.navy
                                  : AppColors.cardBg(context),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: widget.allSelected
                                    ? AppUi.navy
                                    : AppUi.line,
                                width: 1.5,
                              ),
                            ),
                            child: widget.allSelected
                                ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Chevron
                        RotationTransition(
                          turns: _rotateAnimation,
                          child: AppIcon(
                            'arrow-down',
                            size: 22,
                            color: AppColors.textSecondaryC(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Expandable content — hidden in flat mode.
                if (!widget.flat)
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    axisAlignment: -1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        widget.content,
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
