import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../config/routes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/fee_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';
import '../../widgets/common/drill_down_icon_button.dart';

class PayAllFeesScreen extends ConsumerStatefulWidget {
  const PayAllFeesScreen({super.key});

  @override
  ConsumerState<PayAllFeesScreen> createState() => _PayAllFeesScreenState();
}

class _PayAllFeesScreenState extends ConsumerState<PayAllFeesScreen> {
  String _selectedFeeGroup = 'ALL FEES';
  String? _selectedSubFilter;
  String? _expandedGroup;
  bool _isDropdownOpen = false;
  bool _showCartPreview = false;
  final Set<String> _localSelectedFeeIds = {};
  bool _initializedFromCart = false;

  @override
  void initState() {
    super.initState();
  }

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

  /// Get fee group options based on available fees
  List<String> _getFeeGroupOptions(List<FeeModel> fees) {
    final options = <String>['ALL FEES'];

    // Check if there are term fees (non-bus, non-tuition, non-hostel, non-extra, non-exam fees)
    final hasTermFees = fees.any((f) =>
      !_isBusFee(f) &&
      !_isTuitionFee(f) &&
      !_isHostelFee(f) &&
      !_isExtraFee(f) &&
      !_isExamFee(f));
    if (hasTermFees) {
      options.add('Term Fees');
    }

    // Check for tuition fees
    final hasTuitionFees = fees.any((f) => _isTuitionFee(f));
    if (hasTuitionFees) {
      options.add('Tuition Fees');
    }

    // Check for hostel fees
    final hasHostelFees = fees.any((f) => _isHostelFee(f));
    if (hasHostelFees) {
      options.add('Hostel Fees');
    }

    // Check for exam fees
    final hasExamFees = fees.any((f) => _isExamFee(f));
    if (hasExamFees) {
      options.add('Exam Fees');
    }

    // Check for bus fees
    final hasBusFees = fees.any((f) => _isBusFee(f));
    if (hasBusFees) {
      options.add('Bus Fees');
    }

    // Check for extra fees
    final hasExtraFees = fees.any((f) => _isExtraFee(f));
    if (hasExtraFees) {
      options.add('Extra Fees');
    }

    return options;
  }

  /// Check if a fee is an extra/miscellaneous fee
  bool _isExtraFee(FeeModel f) {
    final lowerType = f.demfeetype.toLowerCase();
    final lowerGroup = f.feeGroupName.toLowerCase();
    return lowerType.contains('extra') || lowerGroup.contains('extra') ||
           lowerType.contains('misc') || lowerGroup.contains('misc') ||
           lowerType.contains('other') ||
           lowerType.contains('activity') ||
           lowerType.contains('event');
  }

  /// Get sub-options for a fee group (terms or months)
  List<String> _getSubOptions(String group, List<FeeModel> allFees) {
    if (group == 'ALL FEES' || group == 'Extra Fees') {
      return [];
    }

    List<FeeModel> groupFees;
    if (group == 'Term Fees') {
      groupFees = allFees.where((f) =>
        !_isBusFee(f) &&
        !_isTuitionFee(f) &&
        !_isHostelFee(f) &&
        !_isExtraFee(f)).toList();
      // Return unique term names sorted
      final terms = groupFees.map((f) => f.demfeeterm).toSet().toList()
        ..sort();
      return terms;
    }

    if (group == 'Exam Fees') {
      final examFees = allFees.where((f) => _isExamFee(f)).toList();
      final terms = examFees.map((f) => f.demfeeterm).toSet().toList()..sort();
      return terms;
    }

    // For Bus, Tuition, Hostel — return unique months
    if (group == 'Bus Fees') {
      groupFees = allFees.where((f) => _isBusFee(f)).toList();
    } else if (group == 'Tuition Fees') {
      groupFees = allFees.where((f) => _isTuitionFee(f)).toList();
    } else if (group == 'Hostel Fees') {
      groupFees = allFees.where((f) => _isHostelFee(f)).toList();
    } else {
      return [];
    }

    // Extract unique months sorted chronologically
    final monthMap = <String, DateTime>{};
    for (final fee in groupFees) {
      final date = fee.duedate ?? fee.createdat;
      final label = DateFormat('MMMM yyyy').format(date);
      if (!monthMap.containsKey(label)) {
        monthMap[label] = date;
      }
    }
    final sorted = monthMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.map((e) => e.key).toList();
  }

  /// Get fees for a given group + sub-option combination
  List<FeeModel> _getFeesForSubOption(String group, String subOption, List<FeeModel> allFees) {
    if (group == 'Term Fees') {
      return allFees.where((f) =>
        !_isBusFee(f) && !_isTuitionFee(f) && !_isHostelFee(f) && !_isExtraFee(f) && !_isExamFee(f)
        && f.demfeeterm == subOption).toList();
    } else if (group == 'Exam Fees') {
      return allFees.where((f) => _isExamFee(f) && f.demfeeterm == subOption).toList();
    } else if (group == 'Bus Fees') {
      return allFees.where((f) => _isBusFee(f) && DateFormat('MMMM yyyy').format(f.duedate ?? f.createdat) == subOption).toList();
    } else if (group == 'Tuition Fees') {
      return allFees.where((f) => _isTuitionFee(f) && DateFormat('MMMM yyyy').format(f.duedate ?? f.createdat) == subOption).toList();
    } else if (group == 'Hostel Fees') {
      return allFees.where((f) => _isHostelFee(f) && DateFormat('MMMM yyyy').format(f.duedate ?? f.createdat) == subOption).toList();
    }
    return [];
  }

  /// Filter fees based on selected group and sub-filter
  List<FeeModel> _getFilteredFees(List<FeeModel> allFees) {
    List<FeeModel> groupFiltered;
    if (_selectedFeeGroup == 'ALL FEES') {
      groupFiltered = allFees;
    } else if (_selectedFeeGroup == 'Term Fees') {
      groupFiltered = allFees.where((f) =>
        !_isBusFee(f) &&
        !_isTuitionFee(f) &&
        !_isHostelFee(f) &&
        !_isExtraFee(f) &&
        !_isExamFee(f)).toList();
    } else if (_selectedFeeGroup == 'Tuition Fees') {
      groupFiltered = allFees.where((f) => _isTuitionFee(f)).toList();
    } else if (_selectedFeeGroup == 'Hostel Fees') {
      groupFiltered = allFees.where((f) => _isHostelFee(f)).toList();
    } else if (_selectedFeeGroup == 'Exam Fees') {
      groupFiltered = allFees.where((f) => _isExamFee(f)).toList();
    } else if (_selectedFeeGroup == 'Bus Fees') {
      groupFiltered = allFees.where((f) => _isBusFee(f)).toList();
    } else if (_selectedFeeGroup == 'Extra Fees') {
      groupFiltered = allFees.where((f) => _isExtraFee(f)).toList();
    } else {
      groupFiltered = allFees;
    }

    // Apply sub-filter if set
    if (_selectedSubFilter != null) {
      if (_selectedFeeGroup == 'Term Fees') {
        groupFiltered = groupFiltered.where((f) => f.demfeeterm == _selectedSubFilter).toList();
      } else if (_selectedFeeGroup == 'Bus Fees' ||
                 _selectedFeeGroup == 'Tuition Fees' ||
                 _selectedFeeGroup == 'Hostel Fees') {
        groupFiltered = groupFiltered.where((f) {
          final date = f.duedate ?? f.createdat;
          return DateFormat('MMMM yyyy').format(date) == _selectedSubFilter;
        }).toList();
      }
    }

    return groupFiltered;
  }

  void _clearAllFees(List<FeeModel> fees) {
    final cartNotifier = ref.read(cartProvider.notifier);
    // Remove all local selections from cart
    for (final feeId in _localSelectedFeeIds) {
      cartNotifier.removeFee(feeId);
    }
    setState(() {
      _localSelectedFeeIds.clear();
      _selectedFeeGroup = 'ALL FEES';
      _selectedSubFilter = null;
      _expandedGroup = null;
      _showCartPreview = false;
    });
  }

  /// Add all locally selected fees to the cart
  void _addSelectedFeesToCart(List<FeeModel> allFees) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final feesToAdd = allFees.where((f) => _localSelectedFeeIds.contains(f.id)).toList();
    if (feesToAdd.isNotEmpty) {
      cartNotifier.addFees(feesToAdd);
    }
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

    // Get filtered fees based on selection
    final filteredFees = _getFilteredFees(allPendingFees);

    // Get fee group options
    final feeGroupOptions = _getFeeGroupOptions(allPendingFees);

    // Separate filtered fees by category for display
    final termFees = filteredFees.where((f) => !_isBusFee(f) && !_isTuitionFee(f) && !_isHostelFee(f) && !_isExamFee(f) && !_isExtraFee(f)).toList();
    final busFees = filteredFees.where((f) => _isBusFee(f)).toList();
    final tuitionFees = filteredFees.where((f) => _isTuitionFee(f)).toList();
    final hostelFees = filteredFees.where((f) => _isHostelFee(f)).toList();
    final examFees = filteredFees.where((f) => _isExamFee(f)).toList();

    // Group term fees by term
    final Map<String, List<FeeModel>> feesByTerm = {};
    for (final fee in termFees) {
      final term = fee.demfeeterm;
      feesByTerm.putIfAbsent(term, () => []);
      feesByTerm[term]!.add(fee);
    }

    // Calculate selected amount from ALL fees (not just filtered) so switching groups doesn't hide totals
    final selectedFees = allPendingFees.where((f) => _localSelectedFeeIds.contains(f.id)).toList();
    final selectedAmount = selectedFees.fold<double>(0, (sum, fee) => sum + fee.balancedue);

    // Check if term fees are selected out of order (e.g., II TERM selected without I TERM)
    // Group ALL term fees (not just filtered) by term for validation
    final allTermFees = allPendingFees.where((f) => !_isBusFee(f) && !_isTuitionFee(f) && !_isHostelFee(f) && !_isExamFee(f) && !_isExtraFee(f)).toList();
    final Map<String, List<FeeModel>> allFeesByTerm = {};
    for (final fee in allTermFees) {
      allFeesByTerm.putIfAbsent(fee.demfeeterm, () => []);
      allFeesByTerm[fee.demfeeterm]!.add(fee);
    }
    final allSortedTerms = allFeesByTerm.keys.toList()..sort((a, b) {
      final aDate = allFeesByTerm[a]!.first.duedate ?? allFeesByTerm[a]!.first.createdat;
      final bDate = allFeesByTerm[b]!.first.duedate ?? allFeesByTerm[b]!.first.createdat;
      return aDate.compareTo(bDate);
    });
    bool hasTermOutOfOrder = false;
    for (int i = 1; i < allSortedTerms.length; i++) {
      final currentTermFees = allFeesByTerm[allSortedTerms[i]]!;
      final previousTermFees = allFeesByTerm[allSortedTerms[i - 1]]!;
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
      toolbar: const BreadcrumbBar(currentLabel: 'Pay All Fees'),
      body: allPendingFees.isEmpty
          ? _buildEmptyState()
          : _buildContent(
              context,
              feeGroupOptions,
              allPendingFees,
              filteredFees,
              feesByTerm,
              busFees,
              tuitionFees,
              hostelFees,
              examFees,
              cartState,
            ),
      bottomBar: selectedAmount > 0
          ? _buildBottomBar(context, selectedFees.length, selectedAmount, allFees: allPendingFees, hasTermOutOfOrder: hasTermOutOfOrder)
          : null,
    );
  }

  Widget _buildDesktopGreetingBanner(
      BuildContext context, List<FeeModel> fees) {
    final count = fees.length;
    final hasFees = count > 0;
    final message = hasFees
        ? "Pick the fees you want to pay — $count available."
        : 'No fees available to pay right now.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD2913C),
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
        selectedStudent?.name.trim().split(' ').first ?? 'Student';
    final admissionNo = selectedStudent?.admissionNumber ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$firstName's Pay All Fees",
          style: TextStyle(
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
      BuildContext context, List<FeeModel> fees, CartState cartState) {
    final totalAmount = fees.fold<double>(0, (sum, f) => sum + f.totalAmount);
    final selectedFees = fees
        .where((f) => _localSelectedFeeIds.contains(f.id) ||
            cartState.feeIds.contains(f.id))
        .toList();
    final selectedAmount =
        selectedFees.fold<double>(0, (sum, f) => sum + f.totalAmount);
    return Row(
      children: [
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Total Available',
            value: '₹${NumberFormat('#,##,###').format(totalAmount.toInt())}',
            icon: 'wallet-3',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Selected',
            value: '₹${NumberFormat('#,##,###').format(selectedAmount.toInt())}',
            icon: 'tick-circle',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Items Selected',
            value: '${selectedFees.length}',
            icon: 'task-square',
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
          // Back Button
          DrillDownIconButton(
            svgPath: 'assets/icons/arrow-left.svg',
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.home);
              }
            },
          ),

          // Title
          Expanded(
            child: Text(
              'Pay All Fees',
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

          // Notification Icon - Dark theme with badge
          DrillDownIconButton(
            svgPath: 'assets/main icons/line icons/notification.svg',
            badgeCount: notificationCount,
            onTap: () => context.go(Routes.notifications),
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
          backgroundColor: AppColors.secondary,
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

  Widget _buildContent(
    BuildContext context,
    List<String> feeGroupOptions,
    List<FeeModel> allFees,
    List<FeeModel> filteredFees,
    Map<String, List<FeeModel>> feesByTerm,
    List<FeeModel> busFees,
    List<FeeModel> tuitionFees,
    List<FeeModel> hostelFees,
    List<FeeModel> examFees,
    CartState cartState,
  ) {
    // Sort terms: Term fees first (I TERM, II TERM, etc.), then monthly fees by date
    final sortedTerms = feesByTerm.keys.toList()
      ..sort((a, b) {
        final aFees = feesByTerm[a]!;
        final bFees = feesByTerm[b]!;

        // Check if term name contains "TERM" (prioritize term fees)
        final aIsTerm = a.toUpperCase().contains('TERM');
        final bIsTerm = b.toUpperCase().contains('TERM');

        // Term fees come first
        if (aIsTerm && !bIsTerm) return -1;
        if (!aIsTerm && bIsTerm) return 1;

        // If both are terms or both are months, sort by due date
        final aDate = aFees.first.duedate ?? aFees.first.createdat;
        final bDate = bFees.first.duedate ?? bFees.first.createdat;
        return aDate.compareTo(bDate);
      });

    return Stack(
      children: [
        // Main content - scrollable list
        GestureDetector(
          onTap: () {
            if (_isDropdownOpen) {
              setState(() {
                _isDropdownOpen = false;
                _expandedGroup = null;
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
                _buildDesktopStatCards(context, filteredFees, cartState),
                const SizedBox(height: 20),
              ],

              // Fee Group Filter Card
              _buildFeeGroupFilter(feeGroupOptions, filteredFees),
              const SizedBox(height: 16),

              // Term Fee Cards (sequential: select forward 1â†’2â†’3, unselect backward 3â†’2â†’1)
              ...sortedTerms.asMap().entries.map((entry) {
                final index = entry.key;
                final term = entry.value;
                final currentTermHasSelection = feesByTerm[term]!
                    .any((f) => _localSelectedFeeIds.contains(f.id));
                final currentTermFullySelected = feesByTerm[term]!
                    .every((f) => _localSelectedFeeIds.contains(f.id));
                // Can check: previous term fully selected AND current not fully selected
                final canCheck = !currentTermFullySelected && (index == 0
                    || feesByTerm[sortedTerms[index - 1]]!
                        .every((f) => _localSelectedFeeIds.contains(f.id)));
                // Can uncheck: current has selection AND no later terms have selections
                final noLaterTermsSelected = !sortedTerms.skip(index + 1).any((laterTerm) =>
                    feesByTerm[laterTerm]!.any((f) => _localSelectedFeeIds.contains(f.id)));
                final canUncheck = currentTermHasSelection && noLaterTermsSelected;
                final isTermEnabled = canCheck || canUncheck;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTermCard(term, feesByTerm[term]!, cartState, isEnabled: isTermEnabled),
                );
              }),

              // Tuition fees card
              if (tuitionFees.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTuitionFeesCard(tuitionFees, cartState),
                ),

              // Hostel fees card
              if (hostelFees.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHostelFeesCard(hostelFees, cartState),
                ),

              // Exam fees card
              if (examFees.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildExamFeesCard(examFees, cartState),
                ),

              // Bus fees card
              if (busFees.isNotEmpty)
                _buildBusFeesCard(busFees, cartState),
            ],
          ),
        ),

        // Floating dropdown overlay
        if (_isDropdownOpen)
          Positioned(
            top: 90, // Position below the filter card
            left: 0,
            right: 0,
            child: _buildFloatingDropdown(feeGroupOptions, allFees, filteredFees, cartState),
          ),
      ],
    );
  }

  Widget _buildFeeGroupFilter(List<String> options, List<FeeModel> filteredFees) {
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
          // Fee Group Label
          Text(
            'Fee Group',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryC(context),
            ),
          ),
          const SizedBox(height: 8),

          // Dropdown and Total Amount Row
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
                        Flexible(
                          child: Text(
                            _selectedSubFilter != null
                                ? '$_selectedFeeGroup > $_selectedSubFilter'
                                : _selectedFeeGroup,
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
              Builder(builder: (context) {
                final hasSelection = _localSelectedFeeIds.isNotEmpty || _selectedFeeGroup != 'ALL FEES';
                return GestureDetector(
                  onTap: hasSelection ? () => _clearAllFees(filteredFees) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: hasSelection ? AppColors.iconButtonBg(context) : AppColors.borderC(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                          'filter',
                          size: 18,
                          color: hasSelection ? Colors.white : AppColors.textHintC(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: hasSelection ? Colors.white : AppColors.textHintC(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingDropdown(List<String> options, List<FeeModel> allFees, List<FeeModel> filteredFees, CartState cartState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderC(context)),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isGroupSelected = _selectedFeeGroup == option && _selectedSubFilter == null;
                final isGroupActive = _selectedFeeGroup == option;
                final subOptions = _getSubOptions(option, allFees);
                final hasSubOptions = subOptions.isNotEmpty;
                final isExpanded = _expandedGroup == option;
                final isLast = index == options.length - 1;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main group row
                    Container(
                      decoration: BoxDecoration(
                        color: isGroupSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.cardBg(context),
                        border: (isLast && !isExpanded)
                            ? null
                            : Border(
                                bottom: BorderSide(color: AppColors.borderC(context), width: 1),
                              ),
                      ),
                      child: Row(
                        children: [
                          // Group name — tapping selects ALL fees in group
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFeeGroup = option;
                                  _selectedSubFilter = null;
                                  _expandedGroup = null;
                                  _isDropdownOpen = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                color: Colors.transparent,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isGroupActive ? FontWeight.w600 : FontWeight.w500,
                                          color: isGroupActive ? AppColors.primary : AppColors.textPrimaryC(context),
                                        ),
                                      ),
                                    ),
                                    if (isGroupSelected)
                                      const AppIcon('tick-circle', size: 20, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Expand chevron for groups with sub-options
                          if (hasSubOptions)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _expandedGroup = isExpanded ? null : option;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                color: Colors.transparent,
                                child: AppIcon(
                                  isExpanded ? 'arrow-up' : 'arrow-down',
                                  size: 22,
                                  color: AppColors.textSecondaryC(context),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Sub-options (shown when expanded) with sequential enforcement
                    if (isExpanded)
                      ...subOptions.asMap().entries.map((subEntry) {
                        final subIndex = subEntry.key;
                        final sub = subEntry.value;
                        final isSubSelected = _selectedFeeGroup == option && _selectedSubFilter == sub;
                        final isLastSub = sub == subOptions.last;
                        // Sequential: can only select sub-option if previous sub-option's fees are fully selected
                        final bool isSubEnabled;
                        if (subIndex == 0) {
                          isSubEnabled = true;
                        } else {
                          final prevSub = subOptions[subIndex - 1];
                          final prevFees = _getFeesForSubOption(option, prevSub, allFees);
                          isSubEnabled = prevFees.every((f) => _localSelectedFeeIds.contains(f.id));
                        }
                        return GestureDetector(
                          onTap: isSubEnabled ? () {
                            setState(() {
                              _selectedFeeGroup = option;
                              _selectedSubFilter = sub;
                              _expandedGroup = null;
                              _isDropdownOpen = false;
                            });
                          } : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSubSelected
                                  ? AppColors.primary.withValues(alpha: 0.06)
                                  : AppColors.scaffoldBg(context),
                              border: (isLastSub && isLast)
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        color: AppColors.borderC(context).withValues(alpha: 0.5),
                                        width: 0.5,
                                      ),
                                    ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    sub,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSubSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: !isSubEnabled
                                          ? AppColors.textHintC(context)
                                          : isSubSelected ? AppColors.primary : AppColors.textSecondaryC(context),
                                    ),
                                  ),
                                ),
                                if (isSubSelected)
                                  const AppIcon('tick-circle', size: 18, color: AppColors.primary),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermCard(String term, List<FeeModel> fees, CartState cartState, {bool isEnabled = true}) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => _localSelectedFeeIds.contains(f.id));
    final monthRange = _getTermMonthRange(fees);

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return IgnorePointer(
      ignoring: !isEnabled,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? []
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        term,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryC(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthRange,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondaryC(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // School Badge - color based on fee status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s3,
                    vertical: AppSizes.s1 + 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/school Icons/book.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        academicYear,
                        style: const TextStyle(
                          fontSize: AppSizes.textXs,
                          fontWeight: AppSizes.fontSemibold,
                          color: AppColors.textInverse,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Select All Checkbox
                GestureDetector(
                  onTap: () {
                    final cartNotifier = ref.read(cartProvider.notifier);
                    setState(() {
                      if (allSelected) {
                        for (final fee in fees) {
                          _localSelectedFeeIds.remove(fee.id);
                          cartNotifier.removeFee(fee.id);
                        }
                      } else {
                        for (final fee in fees) {
                          _localSelectedFeeIds.add(fee.id);
                        }
                      }
                    });
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: allSelected ? AppColors.primary : AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: allSelected ? AppColors.primary : AppColors.borderC(context),
                        width: 1.5,
                      ),
                    ),
                    child: allSelected
                        ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Table Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
              child: Row(
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
            ),

            // Divider
            Container(height: 1, color: AppColors.borderC(context)),

            // Fee Items
            ...sortedFees.map((fee) => _buildFeeRow(fee, cartState)),

            // Total Row
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
      ),
      ),
      ),
    );
  }

  String _getTermMonthRange(List<FeeModel> fees) {
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

  Widget _buildTuitionFeesCard(List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => _localSelectedFeeIds.contains(f.id));
    final monthRange = _getTuitionFeesMonthRange(fees);

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TUITION FEES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryC(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthRange,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondaryC(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Academic Year Badge - color based on fee status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s3,
                    vertical: AppSizes.s1 + 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        'book',
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        academicYear,
                        style: const TextStyle(
                          fontSize: AppSizes.textXs,
                          fontWeight: AppSizes.fontSemibold,
                          color: AppColors.textInverse,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Select All Checkbox
                GestureDetector(
                  onTap: () {
                    final cartNotifier = ref.read(cartProvider.notifier);
                    setState(() {
                      if (allSelected) {
                        for (final fee in fees) {
                          _localSelectedFeeIds.remove(fee.id);
                          cartNotifier.removeFee(fee.id);
                        }
                      } else {
                        for (final fee in fees) {
                          _localSelectedFeeIds.add(fee.id);
                        }
                      }
                    });
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: allSelected ? AppColors.primary : AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: allSelected ? AppColors.primary : AppColors.borderC(context),
                        width: 1.5,
                      ),
                    ),
                    child: allSelected
                        ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Table Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
              child: Row(
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
            ),

            // Divider
            Container(height: 1, color: AppColors.borderC(context)),

            // Fee Items
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
                  child: _buildTuitionFeeRow(fee),
                ),
              );
            }),

            // Total Row
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

  Widget _buildTuitionFeeRow(FeeModel fee) {
    final monthName = _extractMonthFromDate(fee);
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderC(context), width: 1),
        ),
      ),
      child: Row(
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
        ],
      ),
    );
  }

  String _extractMonthFromDate(FeeModel fee) {
    final date = fee.duedate ?? fee.createdat;
    return DateFormat('MMMM yyyy').format(date);
  }

  Widget _buildFeeRow(FeeModel fee, CartState cartState) {
    final feeName = fee.feeTypeName; // Use actual fee type name
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderC(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Fee Name with icon
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const AppIcon(
                    'receipt',
                    size: 16,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feeName,
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
        ],
      ),
    );
  }

  Widget _buildHostelFeesCard(List<FeeModel> fees, CartState cartState) {
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

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOSTEL FEES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryC(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthRange,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondaryC(context),
                        ),
                      ),
                    ],
                  ),
                ),
                // Academic Year Badge with hotel icon - color based on fee status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        'home-2',
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        academicYear,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Checkbox for all hostel fees
                GestureDetector(
                  onTap: () {
                    final cartNotifier = ref.read(cartProvider.notifier);
                    setState(() {
                      if (allSelected) {
                        for (final fee in fees) {
                          _localSelectedFeeIds.remove(fee.id);
                          cartNotifier.removeFee(fee.id);
                        }
                      } else {
                        for (final fee in fees) {
                          _localSelectedFeeIds.add(fee.id);
                        }
                      }
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: allSelected ? AppColors.primary : AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: allSelected ? AppColors.primary : AppColors.borderC(context),
                        width: 1.5,
                      ),
                    ),
                    child: allSelected
                        ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Table Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
              child: Row(
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
            ),

            // Divider
            Container(height: 1, color: AppColors.borderC(context)),

            // Fee Items (sequential: forward select, backward unselect)
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
                  child: _buildHostelFeeRow(fee),
                ),
              );
            }),

            // Total Row
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

  Widget _buildHostelFeeRow(FeeModel fee) {
    final monthName = _extractMonthFromDate(fee);
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderC(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Month Name with hotel icon
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const AppIcon(
                    'home-2',
                    size: 16,
                    color: Color(0xFF3B82F6),
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
        ],
      ),
    );
  }

  Widget _buildExamFeesCard(List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getExamFeesMonthRange(fees);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => _localSelectedFeeIds.contains(f.id));

    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return GestureDetector(
      onTap: () {
        final cartNotifier = ref.read(cartProvider.notifier);
        setState(() {
          if (allSelected) {
            for (final fee in fees) {
              _localSelectedFeeIds.remove(fee.id);
              cartNotifier.removeFee(fee.id);
            }
          } else {
            for (final fee in fees) {
              _localSelectedFeeIds.add(fee.id);
            }
          }
        });
      },
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXAM FEES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryC(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthRange,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondaryC(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        'task-square',
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        academicYear,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Checkbox
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: allSelected ? AppColors.primary : AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: allSelected ? AppColors.primary : AppColors.borderC(context),
                      width: 1.5,
                    ),
                  ),
                  child: allSelected
                      ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                  child: _buildExamFeeRow(fee),
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
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _getExamFeesMonthRange(List<FeeModel> fees) {
    if (fees.isEmpty) return '';
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final aDate = a.duedate ?? a.createdat;
        final bDate = b.duedate ?? b.createdat;
        return aDate.compareTo(bDate);
      });
    final firstMonth = DateFormat('MMM').format(sortedFees.first.duedate ?? sortedFees.first.createdat);
    final lastMonth = DateFormat('MMM').format(sortedFees.last.duedate ?? sortedFees.last.createdat);
    if (firstMonth == lastMonth) return firstMonth;
    return '$firstMonth - $lastMonth';
  }

  Widget _buildExamFeeRow(FeeModel fee) {
    final feeName = fee.feeTypeName;
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderC(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/school Icons/exam.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF06B6D4),
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
                        feeName.toUpperCase(),
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
        ],
      ),
    );
  }

  Widget _buildBusFeesCard(List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => _localSelectedFeeIds.contains(f.id));
    final sortedFees = _getSortedBusFees(fees);

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    return GestureDetector(
      onTap: () {
        final cartNotifier = ref.read(cartProvider.notifier);
        setState(() {
          if (allSelected) {
            for (final fee in fees) {
              _localSelectedFeeIds.remove(fee.id);
              cartNotifier.removeFee(fee.id);
            }
          } else {
            for (final fee in fees) {
              _localSelectedFeeIds.add(fee.id);
            }
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? []
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus Fee Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryC(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monthly breakdown',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondaryC(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bus Badge - color based on fee status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s3,
                      vertical: AppSizes.s1 + 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/school Icons/van.svg',
                          width: 14,
                          height: 14,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          academicYear,
                          style: const TextStyle(
                            fontSize: AppSizes.textXs,
                            fontWeight: AppSizes.fontSemibold,
                            color: AppColors.textInverse,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Checkbox
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: allSelected ? AppColors.primary : AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: allSelected ? AppColors.primary : AppColors.borderC(context),
                        width: 1.5,
                      ),
                    ),
                    child: allSelected
                        ? const AppIcon('tick-circle', size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Table Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
                child: Row(
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
              ),

              // Divider
              Container(height: 1, color: AppColors.borderC(context)),

              // Bus Fee Items (sequential: forward select, backward unselect)
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

              // Total Row
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
        ),
      ),
    );
  }

  Widget _buildBusFeeRow(FeeModel fee, CartState cartState) {
    final feeName = fee.feeTypeName; // Use actual fee type name
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderC(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Fee Name with bus icon
          Expanded(
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/school Icons/van.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFF59E0B),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feeName,
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
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int selectedCount, double selectedAmount, {required List<FeeModel> allFees, bool hasTermOutOfOrder = false}) {
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
                  // Fee group icons
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
                  // Count badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: groupIcons.isNotEmpty
                          ? groupIcons[0]['bgColor'] as Color
                          : const Color(0xFFFEF3C7),
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
                              : const Color(0xFFF59E0B),
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
                    '₹ ${NumberFormat('#,##,###').format(selectedAmount.toInt())}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                ],
              ),
              // Button changes based on state
              if (_showCartPreview)
                GestureDetector(
                  onTap: () => context.push(Routes.cart),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2913C),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View List',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        AppIcon('arrow-right-1', size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: (selectedAmount > 0 && !hasTermOutOfOrder)
                      ? () {
                          _addSelectedFeesToCart(allFees);
                          setState(() => _showCartPreview = true);
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: (selectedAmount > 0 && !hasTermOutOfOrder)
                          ? const Color(0xFFD2913C)
                          : const Color(0xFFD2913C).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: (selectedAmount > 0 && !hasTermOutOfOrder)
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon('shopping-cart', size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Add to Queue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -8))],
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
        bgColor = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFF59E0B);
      } else if (type.contains('hostel')) {
        groupKey = 'hostel';
        svgPath = '';
        bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
        iconColor = const Color(0xFF3B82F6);
      } else if (type.contains('exam')) {
        groupKey = 'exam';
        svgPath = 'assets/school Icons/exam.svg';
        bgColor = const Color(0xFF06B6D4).withValues(alpha: 0.1);
        iconColor = const Color(0xFF06B6D4);
      } else {
        groupKey = 'school';
        svgPath = 'assets/school Icons/school.svg';
        bgColor = const Color(0xFFFAF1E4);
        iconColor = const Color(0xFFD2913C);
      }
      if (!seen.contains(groupKey)) {
        seen.add(groupKey);
        icons.add({
          'svgPath': svgPath,
          'bgColor': bgColor,
          'iconColor': iconColor,
          'iconData': groupKey == 'hostel' ? 'home-2' : null,
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
              'No Pending Fees',
              style: TextStyle(
                fontSize: AppSizes.textLg,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryC(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All your fees are paid. Great job!',
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
  List<FeeModel> _getSortedBusFees(List<FeeModel> fees) {
    return List<FeeModel>.from(fees)..sort((a, b) {
      if (a.duedate != null && b.duedate != null) {
        return a.duedate!.compareTo(b.duedate!);
      }
      return a.createdat.compareTo(b.createdat);
    });
  }
}
