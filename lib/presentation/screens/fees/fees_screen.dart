import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  // Mobile background — matches desktop scaffold
  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFE8E7E4);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMedium = Color(0xFF6B6B6B);
  static const Color _textLight = Color(0xFF6B6B6B);

  // Mock data for preview (remove this when real data is available)
  List<FeeModel> get _mockFees => [
    // Mandatory Fees
    FeeModel(
      demId: 1,
      demno: 'DEM001',
      insId: 1,
      inscode: 'INS001',
      yrId: 1,
      demseqtype: 'T',
      stuId: 1,
      stuadmno: 'ADM001',
      stuclass: 'Grade 5',
      demfeeyear: '2025-2026',
      demfeeterm: 'Term 1',
      demfeetype: 'Term Fee',
      demfeecategory: 'Mandatory',
      feeamount: 25000,
      conId: 1,
      balancedue: 25000,
      paidstatus: 'U',
      createdby: 'system',
      createdat: DateTime.now(),
    ),
    FeeModel(
      demId: 2,
      demno: 'DEM002',
      insId: 1,
      inscode: 'INS001',
      yrId: 1,
      demseqtype: 'T',
      stuId: 1,
      stuadmno: 'ADM001',
      stuclass: 'Grade 5',
      demfeeyear: '2025-2026',
      demfeeterm: 'Term 1',
      demfeetype: 'Bus Fee',
      demfeecategory: 'Mandatory',
      feeamount: 8000,
      conId: 1,
      balancedue: 8000,
      paidstatus: 'U',
      createdby: 'system',
      createdat: DateTime.now(),
    ),
    // Secondary Fees
    FeeModel(
      demId: 3,
      demno: 'DEM003',
      insId: 1,
      inscode: 'INS001',
      yrId: 1,
      demseqtype: 'T',
      stuId: 1,
      stuadmno: 'ADM001',
      stuclass: 'Grade 5',
      demfeeyear: '2025-2026',
      demfeeterm: 'Term 1',
      demfeetype: 'Uniform & Text Book',
      demfeecategory: 'Secondary',
      feeamount: 4500,
      conId: 1,
      balancedue: 4500,
      paidstatus: 'U',
      createdby: 'system',
      createdat: DateTime.now(),
    ),
    FeeModel(
      demId: 4,
      demno: 'DEM004',
      insId: 1,
      inscode: 'INS001',
      yrId: 1,
      demseqtype: 'T',
      stuId: 1,
      stuadmno: 'ADM001',
      stuclass: 'Grade 5',
      demfeeyear: '2025-2026',
      demfeeterm: 'Term 1',
      demfeetype: 'Extracurricular',
      demfeecategory: 'Secondary',
      feeamount: 3500,
      conId: 1,
      balancedue: 3500,
      paidstatus: 'U',
      createdby: 'system',
      createdat: DateTime.now(),
    ),
    FeeModel(
      demId: 5,
      demno: 'DEM005',
      insId: 1,
      inscode: 'INS001',
      yrId: 1,
      demseqtype: 'T',
      stuId: 1,
      stuadmno: 'ADM001',
      stuclass: 'Grade 5',
      demfeeyear: '2025-2026',
      demfeeterm: 'Term 1',
      demfeetype: 'Lab Fee',
      demfeecategory: 'Secondary',
      feeamount: 2000,
      conId: 1,
      balancedue: 2000,
      paidstatus: 'U',
      createdby: 'system',
      createdat: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final feesAsync = ref.watch(feesProvider);
    final selectedStudent = ref.watch(selectedStudentProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Column(
          children: [
            // Fixed Header with white SafeArea and subtle shadow
            Container(
              color: _cardBg,
              child: SafeArea(
                bottom: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: _cardBg,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildHeader(context),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
                child: feesAsync.when(
                  loading: () => const LoadingIndicator(),
                  error: (error, stack) => AppErrorWidget(
                    message: error.toString(),
                    onRetry: () => ref.refresh(feesProvider),
                  ),
                  data: (fees) {
                    // Use mock data if no real fees exist (for preview)
                    final displayFees = fees.isEmpty ? _mockFees : fees;

                    // Filter pending/overdue fees for selection (exclude zero amounts)
                    final pendingFees = displayFees
                        .where((f) =>
                            (f.status == FeeStatus.pending || f.status == FeeStatus.overdue) &&
                            f.balanceAmount > 0)
                        .toList();

                    if (pendingFees.isEmpty) {
                      return _buildEmptyState();
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildFeeBreakdownCard(pendingFees, selectedStudent?.name),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);
    final studentName = selectedStudent?.name ?? 'Student';
    final className = selectedStudent?.className ?? 'N/A';
    final courseName = selectedStudent?.courseName ?? 'N/A';
    final hasPhoto = selectedStudent != null &&
        selectedStudent.photoUrl != null &&
        selectedStudent.photoUrl!.trim().isNotEmpty;

    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () => context.go(Routes.profile),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? CachedNetworkImage(
                    imageUrl: selectedStudent.photoUrl!,
                    fit: BoxFit.cover,
                    width: 48,
                    height: 48,
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        _getInitials(studentName),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      _getInitials(studentName),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$courseName | $className',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textLight),
              ),
              const SizedBox(height: 2),
              Text(
                'Hey, ${studentName.split(' ').first}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark, letterSpacing: -0.3),
              ),
            ],
          ),
        ),
        // Cart icon
        _buildHeaderIcon(
          svgPath: 'assets/icons/Cart.svg',
          badgeCount: cartItemCount,
          onTap: () => context.push(Routes.cart),
        ),
        const SizedBox(width: 8),
        // Notification icon
        _buildHeaderIcon(
          svgPath: 'assets/main icons/line icons/notification.svg',
          badgeCount: notificationCount,
          onTap: () => context.go(Routes.notifications),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon({
    IconData? icon,
    String? svgPath,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFD2913C),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            svgPath != null
                ? SvgPicture.asset(svgPath, width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))
                : Icon(icon, size: 20, color: Colors.white),
            if (badgeCount > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildFeeBreakdownCard(List<FeeModel> fees, String? studentName) {
    // Get cart state for selected fees
    final cartState = ref.watch(cartProvider);

    // Calculate total of selected fees from this screen
    final selectedFees = fees.where((f) => cartState.containsFee(f.id)).toList();
    final totalAmount = selectedFees.fold(0.0, (sum, f) => sum + f.balanceAmount);

    // Get academic year and term from first fee (if available)
    const academicYear = 'Academic Year 2025-2026';
    final term = fees.isNotEmpty ? fees.first.term : 'Term 1';

    // Separate mandatory and secondary fees
    final mandatoryFees = fees.where((f) => f.demfeecategory == 'Mandatory').toList();
    final secondaryFees = fees.where((f) => f.demfeecategory != 'Mandatory').toList();

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildCardHeader(academicYear, term),

            const SizedBox(height: AppSizes.s4),

            // Divider
            _buildDivider(),

            const SizedBox(height: AppSizes.s4),

            // Mandatory Fees Section
            if (mandatoryFees.isNotEmpty) ...[
              _buildSectionHeader('Mandatory Fees', AppColors.error),
              const SizedBox(height: AppSizes.s3),
              ...mandatoryFees.map((fee) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.s2),
                child: _buildFeeItem(fee),
              )),
              const SizedBox(height: AppSizes.s4),
            ],

            // Secondary Fees Section
            if (secondaryFees.isNotEmpty) ...[
              _buildSectionHeader('Secondary Fees', AppColors.primary),
              const SizedBox(height: AppSizes.s3),
              ...secondaryFees.map((fee) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.s2),
                child: _buildFeeItem(fee),
              )),
              const SizedBox(height: AppSizes.s4),
            ],

            // Divider before total
            _buildDivider(),

            const SizedBox(height: AppSizes.s4),

            // Total Amount
            _buildTotalRow(totalAmount),

            const SizedBox(height: AppSizes.s4),

            // Divider before button
            _buildDivider(),

            const SizedBox(height: AppSizes.s4),

            // View Cart Button
            _buildViewCartButton(totalAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(String academicYear, String term) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee Breakdown',
              style: TextStyle(
                fontSize: AppSizes.sectionTitle,
                fontWeight: AppSizes.fontSemibold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: AppSizes.s1),
            Text(
              academicYear,
              style: TextStyle(
                fontSize: AppSizes.textXs,
                fontWeight: AppSizes.fontNormal,
                color: _textMedium,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s3,
            vertical: AppSizes.s1 + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            term,
            style: const TextStyle(
              fontSize: AppSizes.textXs,
              fontWeight: AppSizes.fontSemibold,
              color: AppColors.textInverse,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFF0F0F0),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: AppSizes.textBase,
            fontWeight: AppSizes.fontSemibold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeItem(FeeModel fee) {
    final isSelected = ref.watch(cartProvider).containsFee(fee.id);

    // Determine subtitle based on fee type
    final isVanFee = fee.feeTypeName.toUpperCase().contains('VAN');
    String subtitle;

    if (isVanFee) {
      // For VAN FEES, show month from due date
      final month = fee.duedate != null
          ? DateFormat('MMMM yyyy').format(fee.duedate!)
          : fee.demfeeterm;
      final dueDate = fee.duedate != null
          ? DateFormat('dd MMM').format(fee.duedate!)
          : '';
      subtitle = dueDate.isNotEmpty ? '$month • Due: $dueDate' : month;
    } else {
      // For other fees, show term and due date
      final dueDate = fee.duedate != null
          ? DateFormat('dd MMM yyyy').format(fee.duedate!)
          : '';
      subtitle = dueDate.isNotEmpty
          ? '${fee.demfeeterm} • Due: $dueDate'
          : fee.demfeeterm;
    }

    return GestureDetector(
      onTap: () {
        final isSelected = ref.read(cartProvider).containsFee(fee.id);
        if (!isSelected) {
          // Block upcoming/due-today fees when overdue fees exist
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final feeIsOverdue = fee.dueDate.isBefore(today);
          if (!feeIsOverdue) {
            final pendingFees = ref.read(pendingFeesProvider);
            final hasOverdue = pendingFees.any((f) => f.dueDate.isBefore(today));
            if (hasOverdue) {
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
              return;
            }
          }
        }
        ref.read(cartProvider.notifier).toggleFee(fee);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Fee details
            Expanded(
              child: Text(
                fee.feeTypeName,
                style: TextStyle(
                  fontSize: AppSizes.bodyText,
                  fontWeight: isSelected ? AppSizes.fontMedium : AppSizes.fontNormal,
                  color: isSelected ? _textDark : _textMedium,
                  height: 1.47,
                ),
              ),
            ),
            // Amount and checkbox
            Row(
              children: [
                Text(
                  '₹ ${_formatAmount(fee.balanceAmount)}',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: isSelected ? AppColors.accent : _textDark,
                  ),
                ),
                const SizedBox(width: 30),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : _textLight,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const AppIcon(
                          'tick-circle',
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(double totalAmount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Amount',
          style: TextStyle(
            fontSize: AppSizes.sectionTitle,
            fontWeight: AppSizes.fontSemibold,
            color: _textDark,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSizes.s2),
          child: Text(
            '₹ ${_formatAmount(totalAmount)}',
            style: TextStyle(
              fontSize: AppSizes.sectionTitle,
              fontWeight: AppSizes.fontSemibold,
              color: _textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewCartButton(double totalAmount) {
    final isEnabled = totalAmount > 0;
    final cartItemCount = ref.watch(cartItemCountProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.primary : AppColors.filterBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? () => context.go(Routes.cart) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s2,
              vertical: AppSizes.s3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppIcon('shopping-cart', size: 20, color: Colors.white),
                const SizedBox(width: AppSizes.s2),
                Text(
                  'View Cart ($cartItemCount)',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: isEnabled ? Colors.white : _textLight,
                  ),
                ),
                const SizedBox(width: AppSizes.s3),
                AppIcon(
                  'arrow-right-1',
                  size: 24,
                  color: isEnabled ? Colors.white : _textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    // Format with Indian number system (commas)
    if (amount == 0) return '0';

    final parts = amount.toStringAsFixed(0).split('');
    final result = <String>[];

    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        final posFromEnd = parts.length - i;
        if (posFromEnd == 3 || (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0)) {
          result.add(',');
        }
      }
      result.add(parts[i]);
    }

    return result.join('');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.cardPurple,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                'receipt-text',
                size: 48,
                color: AppColors.cardPurpleDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Fees Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no fees assigned to this student yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
