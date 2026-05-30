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

  @override
  void initState() {
    super.initState();
    _selectedSubFilter = null;
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

    if (activeFilterGroup != null && activeFilterGroup.isNotEmpty) {
      // Use the pendingFeesByGroupNameProvider which handles mapping correctly
      filteredFees = ref.watch(pendingFeesByGroupNameProvider(activeFilterGroup));
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


    // Separate fees by category (from filtered fees)
    final termFees = filteredFees.where((f) => !_isBusFee(f) && !_isTuitionFee(f) && !_isHostelFee(f) && !_isExamFee(f)).toList();
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

    // Calculate selected amount from local selection (not cart)
    final selectedFees = filteredFees.where((f) => _localSelectedFeeIds.contains(f.id)).toList();
    final selectedAmount = selectedFees.fold<double>(0, (sum, fee) => sum + fee.balancedue);

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
          : _buildContentWithFilter(context, filteredFees, feesByTerm, busFees, tuitionFees, hostelFees, examFees, cartState),
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
        fees.fold<double>(0, (sum, f) => sum + (f.totalAmount));
    final overdueAmount =
        overdue.fold<double>(0, (sum, f) => sum + (f.totalAmount));
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
          // Back Button - Dark theme
          GestureDetector(
            onTap: () => context.go(Routes.home),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.iconButtonBorder(context)),
              ),
              child: Center(
                child: SvgPicture.asset('assets/icons/arrow-left.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
              ),
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

          // Notification Button - Dark theme
          GestureDetector(
            onTap: () => context.go(Routes.notifications),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.iconButtonBorder(context)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset('assets/main icons/line icons/notification.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                  if (notificationCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.iconButtonBg(context), width: 2),
                        ),
                        child: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
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
          backgroundColor: AppColors.primary,
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
    final groupName = widget.filterGroup?.toUpperCase() ?? '';

    // School Fees - show terms (I TERM, II TERM, etc.) and TUITION FEES option
    if (groupName.contains('SCHOOL')) {
      final allTerms = <String>{};
      // Add terms from regular fees
      allTerms.addAll(feesByTerm.keys.where((t) => t.toUpperCase().contains('TERM')));
      // Add terms from tuition fees
      for (final fee in tuitionFees) {
        if (fee.demfeeterm.toUpperCase().contains('TERM')) {
          allTerms.add(fee.demfeeterm);
        }
      }
      // Note: Hostel fees are NOT included in School Fees group
      final terms = allTerms.toList()..sort(); // Sort alphabetically (I TERM before II TERM)
      // Add TUITION FEES as a separate filter option if tuition fees exist
      if (tuitionFees.isNotEmpty) {
        terms.add('TUITION FEES');
      }
      return terms;
    }

    // Van/Bus Fees - show months
    if (groupName.contains('VAN') || groupName.contains('BUS') || groupName.contains('TRANSPORT')) {
      return _getUniqueMonths(busFees);
    }

    // Tuition Fees - show months
    if (groupName.contains('TUITION')) {
      return _getUniqueMonths(tuitionFees);
    }

    // Hostel Fees - show months
    if (groupName.contains('HOSTEL')) {
      return _getUniqueMonths(hostelFees);
    }

    // Exam Fees - show unique terms
    if (groupName.contains('EXAM')) {
      final terms = examFees.map((f) => f.demfeeterm).toSet().toList()..sort();
      return terms;
    }

    // Default - show terms if available
    if (feesByTerm.isNotEmpty) {
      return feesByTerm.keys.toList()..sort();
    }

    return [];
  }

  /// Extract unique months from fees for monthly filters
  List<String> _getUniqueMonths(List<FeeModel> fees) {
    final months = <String>{};
    for (final fee in fees) {
      final date = fee.duedate ?? fee.createdat;
      final monthName = DateFormat('MMMM yyyy').format(date);
      months.add(monthName);
    }
    // Sort by date
    final monthList = months.toList();
    monthList.sort((a, b) {
      final dateA = DateFormat('MMMM yyyy').parse(a);
      final dateB = DateFormat('MMMM yyyy').parse(b);
      return dateA.compareTo(dateB);
    });
    return monthList;
  }

  Widget _buildContentWithFilter(
    BuildContext context,
    List<FeeModel> filteredFees,
    Map<String, List<FeeModel>> feesByTerm,
    List<FeeModel> busFees,
    List<FeeModel> tuitionFees,
    List<FeeModel> hostelFees,
    List<FeeModel> examFees,
    CartState cartState,
  ) {
    // Get sub-filter options based on the current fee group
    final subFilterOptions = _getSubFilterOptions(feesByTerm, busFees, tuitionFees, hostelFees, examFees);

    // Apply sub-filter to the displayed data
    Map<String, List<FeeModel>> displayedFeesByTerm = feesByTerm;
    List<FeeModel> displayedBusFees = busFees;
    List<FeeModel> displayedTuitionFees = tuitionFees;
    List<FeeModel> displayedHostelFees = hostelFees;
    List<FeeModel> displayedExamFees = examFees;

    if (_selectedSubFilter != null) {
      final groupName = widget.filterGroup?.toUpperCase() ?? '';

      if (groupName.contains('SCHOOL')) {
        if (_selectedSubFilter == 'TUITION FEES') {
          // Show only tuition fees, hide term cards
          displayedFeesByTerm = {};
          displayedTuitionFees = tuitionFees;
        } else {
          // Filter by term - apply to term fees and tuition fees only
          // Note: Hostel fees are NOT part of School Fees group
          displayedFeesByTerm = {
            if (feesByTerm.containsKey(_selectedSubFilter))
              _selectedSubFilter!: feesByTerm[_selectedSubFilter]!
          };
          // Also filter tuition fees by term
          displayedTuitionFees = tuitionFees.where((fee) {
            return fee.demfeeterm == _selectedSubFilter;
          }).toList();
        }
      } else if (groupName.contains('VAN') || groupName.contains('BUS') || groupName.contains('TRANSPORT')) {
        // Filter by month
        displayedBusFees = busFees.where((fee) {
          final date = fee.duedate ?? fee.createdat;
          final monthName = DateFormat('MMMM yyyy').format(date);
          return monthName == _selectedSubFilter;
        }).toList();
      } else if (groupName.contains('TUITION')) {
        // Filter by month
        displayedTuitionFees = tuitionFees.where((fee) {
          final date = fee.duedate ?? fee.createdat;
          final monthName = DateFormat('MMMM yyyy').format(date);
          return monthName == _selectedSubFilter;
        }).toList();
      } else if (groupName.contains('HOSTEL')) {
        // Filter by month
        displayedHostelFees = hostelFees.where((fee) {
          final date = fee.duedate ?? fee.createdat;
          final monthName = DateFormat('MMMM yyyy').format(date);
          return monthName == _selectedSubFilter;
        }).toList();
      } else if (groupName.contains('EXAM')) {
        // Filter by term
        displayedExamFees = examFees.where((fee) {
          return fee.demfeeterm == _selectedSubFilter;
        }).toList();
      }
    }

    // Sort terms: Term fees first (I TERM, II TERM, etc.), then monthly fees by date
    final sortedTerms = displayedFeesByTerm.keys.toList()
      ..sort((a, b) {
        final aFees = displayedFeesByTerm[a]!;
        final bFees = displayedFeesByTerm[b]!;

        final aIsTerm = a.toUpperCase().contains('TERM');
        final bIsTerm = b.toUpperCase().contains('TERM');

        if (aIsTerm && !bIsTerm) return -1;
        if (!aIsTerm && bIsTerm) return 1;

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

              // Sub-Filter Card (shows terms or months based on group type)
              if (subFilterOptions.isNotEmpty)
                _buildSubFilter(subFilterOptions),
              if (subFilterOptions.isNotEmpty)
                const SizedBox(height: 16),

              // Term Fee Cards (sequential: select forward 1→2→3, unselect backward 3→2→1)
              ...sortedTerms.asMap().entries.map((entry) {
                final index = entry.key;
                final term = entry.value;
                final currentTermHasSelection = displayedFeesByTerm[term]!
                    .any((f) => _localSelectedFeeIds.contains(f.id));
                final currentTermFullySelected = displayedFeesByTerm[term]!
                    .every((f) => _localSelectedFeeIds.contains(f.id));
                // Can check: previous term fully selected AND current not fully selected
                final canCheck = !currentTermFullySelected && (index == 0
                    || displayedFeesByTerm[sortedTerms[index - 1]]!
                        .every((f) => _localSelectedFeeIds.contains(f.id)));
                // Can uncheck: current has selection AND no later terms have selections
                final noLaterTermsSelected = !sortedTerms.skip(index + 1).any((laterTerm) =>
                    displayedFeesByTerm[laterTerm]!.any((f) => _localSelectedFeeIds.contains(f.id)));
                final canUncheck = currentTermHasSelection && noLaterTermsSelected;
                final isTermEnabled = canCheck || canUncheck;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTermAccordion(
                    context,
                    term,
                    displayedFeesByTerm[term]!,
                    cartState,
                    'term_$term',
                    isEnabled: isTermEnabled,
                  ),
                );
              }),

              // Tuition fees card
              if (displayedTuitionFees.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTuitionFeesCard(context, displayedTuitionFees, cartState),
                ),

              // Hostel fees card
              if (displayedHostelFees.isNotEmpty &&
                  (widget.filterGroup?.toUpperCase().contains('HOSTEL') ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHostelFeesCard(context, displayedHostelFees, cartState),
                ),

              // Exam fees card
              if (displayedExamFees.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildExamFeesCard(context, displayedExamFees, cartState),
                ),

              // Bus fees card
              if (displayedBusFees.isNotEmpty)
                _buildBusFeesCard(context, displayedBusFees, cartState),
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

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
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

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
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

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
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

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
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

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
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
                  color: Color(0xFFF59E0B),
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
                      color: const Color(0xFF121212),
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
                          _addSelectedFeesToCart(filteredFees);
                          setState(() => _showCartPreview = true);
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: (selectedAmount > 0 && !hasTermOutOfOrder)
                          ? const Color(0xFF121212)
                          : const Color(0xFF121212).withValues(alpha: 0.5),
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

  // Block selection of a fee if it is NOT overdue but overdue fees exist
  bool _shouldBlockFee(FeeModel fee) {
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

  void _toggleAllFees(List<FeeModel> fees, bool allSelected) {
    // Block adding upcoming fees when overdue fees exist
    if (!allSelected && _shouldBlockSelection()) {
      _showOverdueBlockMessage();
      return;
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
  }

  void _toggleSingleFee(FeeModel fee, bool isSelected) {
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
  }

  /// Add all locally selected fees to the cart
  void _addSelectedFeesToCart(List<FeeModel> allFees) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final feesToAdd = allFees.where((f) => _localSelectedFeeIds.contains(f.id)).toList();
    if (feesToAdd.isNotEmpty) {
      cartNotifier.addFees(feesToAdd);
    }
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
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderC(context), width: 1),
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? []
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row — tap to expand/collapse
                GestureDetector(
                  onTap: _toggle,
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryC(context),
                              ),
                            ),
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
                        '₹ ${NumberFormat('#,##,###').format(widget.totalAmount.toInt())}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryC(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            widget.badgeIcon,
                            const SizedBox(width: 4),
                            Text(
                              widget.badgeText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Checkbox — separate tap target
                      GestureDetector(
                        onTap: widget.onToggleAll,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: widget.allSelected ? AppColors.primary : AppColors.cardBg(context),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: widget.allSelected ? AppColors.primary : AppColors.borderC(context),
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
                  ),
                ),
                // Expandable content
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
