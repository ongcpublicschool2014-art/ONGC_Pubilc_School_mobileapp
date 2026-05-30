import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/institution_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/common/desktop_content_card.dart';
import '../../../core/utils/birthday_utils.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/birthday_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Mobile background — matches desktop scaffold
  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMedium = Color(0xFF6B6B6B);
  static const Color _textLight = Color(0xFF9E9E9E);

  bool _birthdayChecked = false;
  bool _orphanSwept = false;
  ProviderSubscription? _studentSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowBirthdayDialog();
      _checkOrphanedPayments();
      _studentSubscription = ref.listenManual(selectedStudentProvider, (previous, next) {
        if (previous == null && next != null && !_birthdayChecked) {
          _checkAndShowBirthdayDialog();
        }
        if (next != null) {
          _orphanSwept = false;
          _checkOrphanedPayments();
        }
      });
    });
  }

  Future<void> _checkOrphanedPayments() async {
    if (_orphanSwept) return;
    final student = ref.read(selectedStudentProvider);
    if (student == null) return;
    _orphanSwept = true;

    final result = await sweepOrphanedPayments(
      insId: student.insId,
      stuId: student.stuId,
    );

    if (!result.hasAny || !mounted) return;

    final messages = <String>[];
    if (result.recovered > 0) {
      messages.add(
        'Recovered ${result.recovered} pending payment${result.recovered > 1 ? 's' : ''} '
        'that completed at the bank.',
      );
    }
    if (result.failed > 0) {
      messages.add(
        'Marked ${result.failed} stale pending payment${result.failed > 1 ? 's' : ''} as failed.',
      );
    }

    // Refresh providers so the user sees updated data
    ref.invalidate(feesProvider);
    ref.invalidate(paymentsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.blue, size: 28),
            SizedBox(width: 10),
            Text('Pending Payment Update'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: messages.map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(m, style: const TextStyle(fontSize: 14)),
          )).toList(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _studentSubscription?.close();
    super.dispose();
  }

  Future<void> _checkAndShowBirthdayDialog() async {
    if (_birthdayChecked) return;

    final student = ref.read(selectedStudentProvider);
    final shouldShow = await BirthdayUtils.shouldShowBirthdayDialog(student);

    if (shouldShow && mounted) {
      _birthdayChecked = true;
      await BirthdayUtils.markAsShown(student!.stuId);
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => BirthdayDialog(
          studentName: student.name,
          onDismiss: () => Navigator.of(dialogContext).pop(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    ref.watch(cartRestorerProvider); // Restore cart from DB on startup
    final feeSummaryAsync = ref.watch(feeSummaryProvider);
    final feesByGroup = ref.watch(pendingFeesByGroupProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);
    final overdueGroups = ref.watch(overdueByGroupProvider);
    final dueSoonGroups = ref.watch(dueSoonByGroupProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Column(
        children: [
          // Desktop: no page title (shown in top bar) | Mobile: header with nav icons
          if (!context.isDesktop)
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
                        child: _buildHeader(context, selectedStudent, cartItemCount, notificationCount),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: context.isDesktop
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!context.isDesktop) const SizedBox(height: 24),
                  if (context.isDesktop) const SizedBox(height: 4),

                  // Desktop: dark greeting banner + dashboard title + stat cards
                  if (context.isDesktop) ...[
                    _buildDesktopGreetingBanner(context, feeSummaryAsync),
                    const SizedBox(height: 18),
                    _buildDesktopDashboardTitle(context, selectedStudent),
                    const SizedBox(height: 20),
                    _buildDesktopStatCards(context, feeSummaryAsync, overdueGroups, dueSoonGroups),
                    const SizedBox(height: 20),
                  ],

                  // Mobile only: balance card
                  if (!context.isDesktop) ...[
                    _buildBalanceCard(context, feeSummaryAsync),
                    const SizedBox(height: 28),
                  ],

                  // Spending/Fee Categories Section
                  _buildSpendingSection(context, feesByGroup),

                  const SizedBox(height: 24),

                  // Activity Section - Overdue & Due Soon
                  _buildActivitySection(context, overdueGroups, dueSoonGroups),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic selectedStudent, int cartItemCount, int notificationCount) {
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
              color: AppColors.primary,
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
          color: const Color(0xFF121212),
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

  Widget _buildBalanceCard(BuildContext context, AsyncValue<FeeSummary> feeSummaryAsync) {
    final feeSummary = feeSummaryAsync.valueOrNull;
    final totalPending = feeSummary?.totalPending ?? 0;
    final selectedStudent = ref.watch(selectedStudentProvider);
    final studentName = selectedStudent?.name ?? 'Student';

    final academicYearAsync = ref.watch(activeYearLabelProvider);
    final now = DateTime.now();
    final academicYear = academicYearAsync.valueOrNull ??
        (now.month >= 6
            ? '${now.year}-${now.year + 1}'
            : '${now.year - 1}-${now.year}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle diagonal lines pattern overlay
          Positioned(
            top: -20,
            right: -20,
            child: Opacity(
              opacity: 0.06,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(80),
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: Opacity(
              opacity: 0.04,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: label + icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance Fees Due',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(
                      'wallet-3',
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Amount
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '₹${NumberFormat('#,##,###').format(totalPending.clamp(0, double.infinity))}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Bottom row: student name + academic year
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    academicYear,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingSection(BuildContext context, Map<String, double> feesByGroup) {
    final categories = [
      {'name': 'School Fees', 'icon': 'book', 'color': const Color(0xFFD2913C), 'iconBgColor': const Color(0xFFFAF1E4)},
      {'name': 'Van Fees', 'icon': 'bus', 'color': const Color(0xFFF59E0B), 'iconBgColor': const Color(0xFFFEF3C7)},
      {'name': 'Exam Fees', 'icon': 'task-square', 'color': const Color(0xFF06B6D4), 'iconBgColor': const Color(0xFFCFFAFE)},
      {'name': 'Other', 'icon': 'more', 'color': AppColors.cardPurple, 'iconBgColor': const Color(0xFFF3E8FF)},
    ];

    // Sort fee groups by amount in descending order
    final sortedEntries = feesByGroup.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        if (!context.isDesktop)
          _buildMobileFeeBreakupCard(context, feesByGroup, sortedEntries, categories),
        if (context.isDesktop)
          DesktopContentCard(
            title: 'Fees Breakup',
            trailing: GestureDetector(
              onTap: () => context.push(Routes.payAllFees),
              child: Text(
                'Show all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLink,
                ),
              ),
            ),
            child: SizedBox(
              height: 165,
              child: sortedEntries.length > 4
                  ? _buildSpendingCarousel(context, sortedEntries)
                  : _buildSpendingFourSlots(context, sortedEntries),
            ),
          )
        else
          const SizedBox.shrink(), // Mobile uses _buildMobileFeeBreakupCard above
      ],
    );
  }

  /// ≤ 4 groups: render each real group as a card in a fixed 4-slot row,
  /// padded with empty placeholder slots (no label, no number) for unused slots.
  Widget _buildSpendingFourSlots(
      BuildContext context, List<MapEntry<String, double>> entries) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: i < entries.length
                ? _buildSpendingCardForGroup(
                    context: context,
                    groupName: entries[i].key,
                    amount: entries[i].value,
                    isFirst: i == 0,
                  )
                : _buildEmptySpendingSlot(context),
          ),
        ],
      ],
    );
  }

  /// > 4 groups: horizontal carousel of fee-group cards.
  Widget _buildSpendingCarousel(
      BuildContext context, List<MapEntry<String, double>> entries) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) => SizedBox(
        width: 180,
        child: _buildSpendingCardForGroup(
          context: context,
          groupName: entries[i].key,
          amount: entries[i].value,
          isFirst: i == 0,
        ),
      ),
    );
  }

  /// Wraps [_buildSpendingCard] with per-group icon/color lookup so slot and
  /// carousel rendering stay consistent.
  Widget _buildSpendingCardForGroup({
    required BuildContext context,
    required String groupName,
    required double amount,
    required bool isFirst,
  }) {
    final meta = _getIconForFeeGroup(groupName);
    return _buildSpendingCard(
      context: context,
      icon: meta['icon'] as String?,
      svgPath: meta['svgPath'] as String?,
      label: _toTitleCase(groupName),
      groupName: groupName,
      amount: amount,
      primaryColor: meta['color'] as Color,
      iconBgColor: meta['iconBgColor'] as Color,
      isFirst: isFirst,
      fixedWidth: false,
    );
  }

  /// Placeholder used when a student has no fees for a given category.
  /// Keeps the slot visually reserved without labelling it.
  Widget _buildEmptySpendingSlot(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.filterBg(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderC(context).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildSpendingCard({
    required BuildContext context,
    String? icon,
    String? svgPath,
    required String label,
    required String groupName,
    required double amount,
    required Color primaryColor,
    required Color iconBgColor,
    required bool isFirst,
    bool fixedWidth = true,
  }) {
    // First card has colored background, others have white background
    final bool hasColoredBg = isFirst && amount > 0;

    return GestureDetector(
      onTap: () => context.push('${Routes.allPendingFees}?group=${Uri.encodeComponent(groupName)}'),
      child: Container(
        width: fixedWidth ? 160 : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasColoredBg ? primaryColor : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: hasColoredBg
              ? null
              : Border.all(
                  color: AppColors.borderC(context),
                  width: 1,
                ),
          boxShadow: hasColoredBg
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppColors.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Icon and Due badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasColoredBg
                        ? Colors.white.withValues(alpha: 0.2)
                        : iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: svgPath != null
                        ? SvgPicture.asset(
                            svgPath,
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              hasColoredBg ? Colors.white : primaryColor,
                              BlendMode.srcIn,
                            ),
                          )
                        : AppIcon(
                            icon ?? 'receipt',
                            size: 22,
                            color: hasColoredBg ? Colors.white : primaryColor,
                          ),
                  ),
                ),
                // Due badge
                if (amount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasColoredBg
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Due',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasColoredBg
                                ? Colors.white
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 2),
                        AppIcon(
                          'arrow-up',
                          size: 12,
                          color: hasColoredBg
                              ? Colors.white
                              : const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: hasColoredBg
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.textSecondaryC(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Amount and arrow row
            Row(
              children: [
                Expanded(
                  child: Text(
                    NumberFormat('#,##,###').format(amount.toInt()),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: hasColoredBg ? Colors.white : AppColors.textPrimaryC(context),
                    ),
                  ),
                ),
                AppIcon(
                  'arrow-right-1',
                  size: 14,
                  color: hasColoredBg ? Colors.white : AppColors.textSecondaryC(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile fee breakup — reference-style card with 2-column grid
  Widget _buildMobileFeeBreakupCard(
    BuildContext context,
    Map<String, double> feesByGroup,
    List<MapEntry<String, double>> sortedEntries,
    List<Map<String, dynamic>> categories,
  ) {
    // Build grid items from fee data or placeholders
    final List<_FeeGridItem> items = [];
    if (feesByGroup.isEmpty) {
      for (final cat in categories) {
        items.add(_FeeGridItem(
          label: cat['name'] as String,
          amount: 0,
          color: cat['color'] as Color,
          iconBgColor: cat['iconBgColor'] as Color,
          icon: cat['icon'] as String?,
          svgPath: cat['svgPath'] as String?,
          groupName: cat['name'] as String,
        ));
      }
    } else {
      for (final entry in sortedEntries) {
        final iconData = _getIconForFeeGroup(entry.key);
        items.add(_FeeGridItem(
          label: _toTitleCase(entry.key),
          amount: entry.value,
          color: iconData['color'] as Color,
          iconBgColor: iconData['iconBgColor'] as Color,
          icon: iconData['icon'] as String?,
          svgPath: iconData['svgPath'] as String?,
          groupName: entry.key,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          children: [
            const Expanded(
              child: Text(
                'Fees Breakup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark),
              ),
            ),
            GestureDetector(
              onTap: () => context.push(Routes.payAllFees),
              child: const Text(
                'Show all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Horizontal carousel of fee cards
        SizedBox(
          height: 155,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildFeeCarouselCard(context, items[index], isFirst: index == 0),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeCarouselCard(BuildContext context, _FeeGridItem item, {bool isFirst = false}) {
    final bool isDark = isFirst && item.amount > 0;

    return GestureDetector(
      onTap: () => context.push('${Routes.allPendingFees}?group=${Uri.encodeComponent(item.groupName)}'),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.primary : _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : const Color(0x0F000000),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Arrow row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : item.iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: item.svgPath != null
                        ? SvgPicture.asset(
                            item.svgPath!,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              isDark ? Colors.white : item.color,
                              BlendMode.srcIn,
                            ),
                          )
                        : AppIcon(
                            item.icon ?? 'receipt',
                            size: 20,
                            color: isDark ? Colors.white : item.color,
                          ),
                  ),
                ),
                // Arrow up-right icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : const Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/arrow-up-right.svg',
                      width: 14,
                      height: 14,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : const Color(0xFF6B6B6B),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Amount — big and bold
            Text(
              item.amount > 0
                  ? '₹${NumberFormat('#,##,###').format(item.amount.toInt())}'
                  : '₹0',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : _textDark,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Fee group name
            Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : _textMedium,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// "Nearby jobs" style fee item — white card row with icon, title, subtitle, amount
  Widget _buildNearbyFeeItem(BuildContext context, FeeGroupSummary group, Color statusColor, {required String filterStatus, bool isDisabled = false}) {
    final now = DateTime.now();
    String timeInfo = '';
    if (group.nearestDueDate != null) {
      if (group.isOverdue) {
        final days = now.difference(group.nearestDueDate!).inDays;
        timeInfo = '$days days overdue';
      } else {
        final days = group.nearestDueDate!.difference(now).inDays;
        timeInfo = days == 0 ? 'Due today' : 'Due in $days days';
      }
    }

    final iconData = _getIconForFeeGroup(group.groupName);

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isDisabled ? null : () => context.push('${Routes.allPendingFees}?group=${Uri.encodeComponent(group.groupName)}&status=$filterStatus'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconData['iconBgColor'] as Color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppIcon(
                    iconData['icon'] as String? ?? 'receipt',
                    size: 22,
                    color: iconData['color'] as Color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _toTitleCase(group.groupName),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (group.periodText.isNotEmpty) group.periodText,
                        if (timeInfo.isNotEmpty) timeInfo,
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: timeInfo.isNotEmpty ? statusColor : _textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '₹${NumberFormat('#,##,###').format(group.totalAmount.toInt())}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 8),
              const AppIcon(
                'arrow-right-1',
                size: 14,
                color: _textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context, List<FeeGroupSummary> overdueGroups, List<FeeGroupSummary> dueSoonGroups) {
    final hasOverdue = overdueGroups.isNotEmpty;
    final hasDueSoon = dueSoonGroups.isNotEmpty;
    final hasAnyFees = hasOverdue || hasDueSoon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasAnyFees && !context.isDesktop)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Fee Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(Routes.allPendingFees),
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEmptyActivity(context),
            ],
          )
        else if (context.isDesktop)
          DesktopContentCard(
            title: 'Fee Status',
            trailing: GestureDetector(
              onTap: () => context.push(Routes.allPendingFees),
              child: Text(
                'View all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLink,
                ),
              ),
            ),
            hasPadding: false,
            child: _buildDesktopFeeTable(context, overdueGroups, dueSoonGroups, hasOverdue, hasDueSoon),
          )
        else
          // Mobile: Fee Status — flat list like "Nearby jobs"
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Fee Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(Routes.allPendingFees),
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Overdue items
              if (hasOverdue)
                ...overdueGroups.map((group) =>
                  _buildNearbyFeeItem(context, group, AppColors.error, filterStatus: 'overdue'),
                ),
              // Due soon items
              if (hasDueSoon)
                ...dueSoonGroups.map((group) =>
                  _buildNearbyFeeItem(context, group, AppColors.warning, filterStatus: 'dueSoon', isDisabled: hasOverdue),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDesktopFeeTable(BuildContext context, List<FeeGroupSummary> overdueGroups, List<FeeGroupSummary> dueSoonGroups, bool hasOverdue, bool hasDueSoon) {
    const headerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5);
    final allRows = <Widget>[];

    if (hasOverdue) {
      for (final group in overdueGroups) {
        allRows.add(_buildDesktopFeeRow(context, group, AppColors.error, filterStatus: 'overdue'));
        allRows.add(Divider(height: 1, color: AppColors.borderC(context)));
      }
    }
    if (hasDueSoon) {
      for (final group in dueSoonGroups) {
        allRows.add(_buildDesktopFeeRow(context, group, AppColors.warning, filterStatus: 'dueSoon', isDisabled: hasOverdue));
        allRows.add(Divider(height: 1, color: AppColors.borderC(context)));
      }
    }
    if (allRows.isNotEmpty) allRows.removeLast(); // remove trailing divider

    return Column(
      children: [
        // Header row — green band with white labels
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AppColors.primary,
          child: Row(
            children: const [
              SizedBox(width: 52), // icon (40) + gap (12)
              Expanded(flex: 3, child: Text('Fee Group', style: headerStyle)),
              Expanded(flex: 2, child: Text('Period', style: headerStyle)),
              SizedBox(width: 140, child: Text('Status', style: headerStyle)),
              SizedBox(
                  width: 100,
                  child: Text('Amount',
                      textAlign: TextAlign.right, style: headerStyle)),
              SizedBox(width: 26), // trailing chevron column
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.borderC(context)),
        // Data rows
        ...allRows,
      ],
    );
  }

  Widget _buildDesktopFeeRow(BuildContext context, FeeGroupSummary group, Color statusColor, {required String filterStatus, bool isDisabled = false}) {
    final now = DateTime.now();
    String timeInfo = '';
    if (group.nearestDueDate != null) {
      if (group.isOverdue) {
        final days = now.difference(group.nearestDueDate!).inDays;
        timeInfo = '$days days overdue';
      } else {
        final days = group.nearestDueDate!.difference(now).inDays;
        timeInfo = days == 0 ? 'Due today' : 'Due in $days days';
      }
    }

    String groupIcon = 'receipt';
    Color groupBg = AppColors.cardPurple;
    Color groupIconColor = AppColors.cardPurpleDark;
    final lowerName = group.groupName.toLowerCase();
    if (lowerName.contains('school') || lowerName.contains('tuition')) {
      groupIcon = 'book';
      groupBg = AppColors.cardGreen;
      groupIconColor = AppColors.cardGreenDark;
    } else if (lowerName.contains('van') || lowerName.contains('bus') || lowerName.contains('transport')) {
      groupIcon = 'bus';
      groupBg = const Color(0xFFFEF3C7);
      groupIconColor = const Color(0xFFF59E0B);
    } else if (lowerName.contains('hostel')) {
      groupIcon = 'home-2';
      groupBg = const Color(0xFFDBEAFE);
      groupIconColor = const Color(0xFF3B82F6);
    } else if (lowerName.contains('exam')) {
      groupIcon = 'task-square';
      groupBg = const Color(0xFFCFFAFE);
      groupIconColor = const Color(0xFF06B6D4);
    }

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: isDisabled ? null : () => context.push('${Routes.allPendingFees}?group=${Uri.encodeComponent(group.groupName)}&status=$filterStatus'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Icon chip — rounded square to match reference's Latest Orders look
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: groupBg, borderRadius: BorderRadius.circular(10)),
                child: AppIcon(groupIcon, size: 20, color: groupIconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  _toTitleCase(group.groupName),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryC(context)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  group.periodText,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryC(context)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status — colored text only (no pill), matching reference
              SizedBox(
                width: 140,
                child: Text(
                  timeInfo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  '₹${NumberFormat('#,##,###').format(group.totalAmount.toInt())}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryC(context)),
                ),
              ),
              const SizedBox(width: 12),
              AppIcon(
                'arrow-right-1',
                size: 14,
                color: AppColors.textHintC(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActivity(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Green circle with checkmark
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppIcon(
                  'shield',
                  size: 28,
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                const Positioned(
                  bottom: 10,
                  right: 10,
                  child: AppIcon(
                    'tick-circle',
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All caught up!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No overdue or upcoming fees. You\'re all set!',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Arrow
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const AppIcon(
              'arrow-right-1',
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Map<String, dynamic> _getIconForFeeGroup(String groupName) {
    final lowerName = groupName.toLowerCase();

    if (lowerName.contains('school') || lowerName.contains('tuition')) {
      return {
        'icon': 'book',
        'color': const Color(0xFFD2913C),
        'iconBgColor': const Color(0xFFFAF1E4),
      };
    } else if (lowerName.contains('van') || lowerName.contains('bus') || lowerName.contains('transport')) {
      return {
        'icon': 'bus',
        'color': const Color(0xFFF59E0B),
        'iconBgColor': const Color(0xFFFEF3C7),
      };
    } else if (lowerName.contains('hostel')) {
      return {
        'icon': 'home-2',
        'color': const Color(0xFF3B82F6),
        'iconBgColor': const Color(0xFFDBEAFE),
      };
    } else if (lowerName.contains('exam') || lowerName.contains('test')) {
      return {
        'icon': 'task-square',
        'color': const Color(0xFF06B6D4),
        'iconBgColor': const Color(0xFFCFFAFE),
      };
    } else {
      return {
        'icon': 'receipt',
        'color': AppColors.cardPurple,
        'iconBgColor': const Color(0xFFF3E8FF),
      };
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Desktop-only widgets
  // ────────────────────────────────────────────────────────────────

  Widget _buildDesktopGreetingBanner(
      BuildContext context, AsyncValue<FeeSummary> feeSummaryAsync) {
    final summary = feeSummaryAsync.valueOrNull;
    final pendingCount = summary?.pendingCount ?? 0;
    final hasPending = pendingCount > 0;
    final message = hasPending
        ? "Hi! You have $pendingCount pending "
            "${pendingCount == 1 ? 'fee' : 'fees'}."
        : "Hi! You're all caught up.";
    final ctaLabel = hasPending ? 'Pay' : null;

    return GestureDetector(
      onTap: hasPending ? () => context.push(Routes.payAllFees) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (ctaLabel != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      ctaLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const AppIcon(
              'arrow-right-1',
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopDashboardTitle(
      BuildContext context, dynamic selectedStudent) {
    final studentName =
        (selectedStudent?.name as String?)?.trim().split(' ').first ?? 'Student';
    final admissionNo = (selectedStudent?.admissionNumber as String?) ?? '—';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$studentName's Dashboard",
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
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStatCards(
    BuildContext context,
    AsyncValue<FeeSummary> feeSummaryAsync,
    List<FeeGroupSummary> overdueGroups,
    List<FeeGroupSummary> dueSoonGroups,
  ) {
    final feeSummary = feeSummaryAsync.valueOrNull;
    final totalPending = feeSummary?.totalPending ?? 0;
    final totalOverdue = overdueGroups.fold(0.0, (sum, g) => sum + g.totalAmount);
    final totalDueSoon = dueSoonGroups.fold(0.0, (sum, g) => sum + g.totalAmount);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Total Dues',
            amount: totalPending,
            icon: 'wallet-3',
            iconBg: AppColors.primary.withValues(alpha: 0.12),
            iconColor: AppColors.primary,
            onTap: () => context.push(Routes.payAllFees),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Overdue',
            amount: totalOverdue,
            icon: 'warning-2',
            iconBg: AppColors.errorLight,
            iconColor: AppColors.error,
            onTap: () => context.push('${Routes.allPendingFees}?status=overdue'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Total Paid',
            amount: feeSummary?.totalPaid ?? 0,
            icon: 'tick-circle',
            iconBg: AppColors.primary.withValues(alpha: 0.12),
            iconColor: AppColors.primary,
            onTap: () => context.push(Routes.paidFees),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Due Soon',
            amount: totalDueSoon,
            icon: 'clock',
            iconBg: AppColors.warningLight,
            iconColor: AppColors.warning,
            onTap: () => context.push('${Routes.allPendingFees}?status=dueSoon'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required double amount,
    required String icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: dark icon tile + label (reference style)
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
                AppIcon(
                  'arrow-right-1',
                  size: 14,
                  color: AppColors.textHintC(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Amount
            Text(
              '₹${NumberFormat('#,##,###').format(amount.clamp(0, double.infinity).toInt())}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryC(context),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeGridItem {
  final String label;
  final double amount;
  final Color color;
  final Color iconBgColor;
  final String? icon; // AppIcon name from assets/icons/linear
  final String? svgPath;
  final String groupName;

  const _FeeGridItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.iconBgColor,
    this.icon,
    this.svgPath,
    required this.groupName,
  });
}
