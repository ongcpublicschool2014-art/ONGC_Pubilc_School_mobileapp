import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_ui.dart';
import '../../../data/models/fee_model.dart';
import '../../../data/models/payment_model.dart';
import '../../widgets/update_dialog.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/institution_provider.dart';
import '../../providers/bus_provider.dart';
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

  bool _birthdayChecked = false;
  bool _orphanSwept = false;
  ProviderSubscription? _studentSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybePromptUpdate(context); // asks at most once per app run
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
    // True while the detailed fee list is still loading (e.g. right after
    // switching students) — used to show skeletons instead of ₹0 placeholders.
    final feesLoading = ref.watch(feesProvider).isLoading;
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);
    final overdueGroups = ref.watch(overdueByGroupProvider);
    final dueSoonGroups = ref.watch(dueSoonByGroupProvider);

    final groupSummaries = ref.watch(pendingGroupSummariesProvider);

    return Scaffold(
      backgroundColor:
          context.isDesktop ? AppColors.scaffoldBg(context) : AppUi.pageBg,
      body: Column(
        children: [
          // Desktop: no page title (shown in top bar) | Mobile: header with nav icons
          if (!context.isDesktop)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: _buildHeader(
                    context, selectedStudent, cartItemCount, notificationCount),
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

                  // Mobile: balance hero, then the fee groups, then what was
                  // paid recently -- owe, act, confirm, in that order.
                  if (!context.isDesktop) ...[
                    _buildBalanceCard(context, feeSummaryAsync, groupSummaries),
                    _buildDueNote(feeSummaryAsync),
                    _buildBusCard(context),
                    const SizedBox(height: 26),
                    _buildFeesSection(context, groupSummaries,
                        isLoading: feesLoading && feesByGroup.isEmpty),
                    const SizedBox(height: 26),
                    _buildRecentPaymentsSection(context),
                    const SizedBox(height: 20),
                  ],

                  if (context.isDesktop) ...[
                    _buildSpendingSection(context, feesByGroup, isLoading: feesLoading),
                    const SizedBox(height: 24),
                    _buildActivitySection(context, overdueGroups, dueSoonGroups),
                    const SizedBox(height: 24),
                  ],
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
    final hasPhoto = selectedStudent != null &&
        selectedStudent.photoUrl != null &&
        selectedStudent.photoUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      // Desktop top bar: a cream card, ink text.
      decoration: AppUi.cardBox(r: 18),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => context.go(Routes.profile),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft,
                border: Border.all(color: AppColors.primaryLine),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: selectedStudent.photoUrl!,
                      fit: BoxFit.cover,
                      width: 58,
                      height: 58,
                      errorWidget: (context, url, error) =>
                          _avatarInitials(studentName),
                    )
                  : _avatarInitials(studentName),
            ),
          ),
          const SizedBox(width: 14),
          // The student, named
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  studentName.split(' ').first.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildHeaderIcon(
            svgPath: 'assets/icons/Cart.svg',
            badgeCount: cartItemCount,
            onTap: () => context.push(Routes.cart),
          ),
          const SizedBox(width: 10),
          _buildHeaderIcon(
            svgPath: 'assets/main icons/line icons/notification.svg',
            badgeCount: notificationCount,
            onTap: () => context.go(Routes.notifications),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitials(String name) => Center(
        child: Text(
          _getInitials(name),
          // Avatar letters: Fraunces, as on the desktop.
          style: AppFonts.heading(size: 21, color: AppColors.primaryDark),
        ),
      );

  Widget _buildHeaderIcon({
    IconData? icon,
    String? svgPath,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        // Translucent white on the navy card: a solid disc would read as a
        // second card sitting on the first.
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryLine),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            svgPath != null
                ? SvgPicture.asset(svgPath,
                    width: 20,
                    height: 20,
                    colorFilter:
                        const ColorFilter.mode(AppColors.primaryDark, BlendMode.srcIn))
                : Icon(icon, size: 20, color: AppColors.primaryDark),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8453A),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.card, width: 1.5),
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700),
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
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// How a due date reads to a parent, and how urgent it looks.
  ///
  /// Returns null when there is nothing dated to say.
  ({String label, Color bg, Color ink, String? helper})? _dueBadge(
      DateTime? due) {
    if (due == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final days = day.difference(today).inDays;
    final on = DateFormat('d MMM').format(due);

    if (days < 0) {
      return (
        label: days == -1 ? 'Overdue by a day' : 'Overdue by ${-days} days',
        bg: AppUi.failBg,
        ink: AppUi.failInk,
        helper: 'Due on $on. Clear it to avoid a late fee.',
      );
    }
    if (days == 0) {
      return (
        label: 'Due today',
        bg: AppUi.dueBg,
        ink: AppUi.dueInk,
        helper: 'Pay today to avoid a late fee',
      );
    }
    if (days == 1) {
      return (
        label: 'Due tomorrow',
        bg: AppUi.dueBg,
        ink: AppUi.dueInk,
        helper: 'Pay by $on to avoid a late fee',
      );
    }
    if (days <= 14) {
      return (
        label: 'Due in $days days',
        bg: AppUi.dueBg,
        ink: AppUi.dueInk,
        helper: 'Pay by $on to avoid a late fee',
      );
    }
    return (
      label: 'Due $on',
      bg: AppUi.fill,
      ink: AppUi.inkMuted,
      helper: 'Pay by $on to avoid a late fee',
    );
  }

  Widget _buildBalanceCard(BuildContext context,
      AsyncValue<FeeSummary> feeSummaryAsync, List<FeeGroupSummary> groups) {
    final feeSummary = feeSummaryAsync.valueOrNull;
    final totalPending =
        (feeSummary?.totalPending ?? 0).clamp(0, double.infinity);
    final selectedStudent = ref.watch(selectedStudentProvider);
    final studentName = selectedStudent?.name ?? 'Student';

    final academicYearAsync = ref.watch(activeYearLabelProvider);
    final now = DateTime.now();
    final academicYear = academicYearAsync.valueOrNull ??
        (now.month >= 6
            ? '${now.year}-${now.year + 1}'
            : '${now.year - 1}-${now.year}');

    final badge = _dueBadge(feeSummary?.nextDueDate);
    final settled = totalPending <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF0A4D47), Color(0xFF0F6B63)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(10, 77, 71, 0.45), offset: Offset(0, 14), blurRadius: 28, spreadRadius: -16),
        ],
      ),
      child: Stack(
        children: [
          // Two faint rings, bleeding off the right edge -- the card's only
          // ornament, and the reason the amount has room to be this large.
          Positioned(
            top: -26,
            right: -26,
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10), width: 1),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -70,
            child: Container(
              width: 236,
              height: 236,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settled ? 'All fees cleared' : 'Balance fees due',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        if (badge != null && !settled) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            // Marigold "action needed" pill (desktop).
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppIcon('clock-1',
                                    size: 14, color: Color(0xFF2A1A04)),
                                const SizedBox(width: 7),
                                Flexible(
                                  child: Text(
                                    badge.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2A1A04),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AppIcon(
                        'wallet-3',
                        size: 20,
                        color: AppColors.onPrimaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${NumberFormat('#,##,###').format(totalPending.toInt())}',
                  style: AppFonts.figure(size: 44, weight: FontWeight.w800, color: AppColors.onPrimary),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      studentName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimaryMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Desktop AY chip: marigold-soft with gold ink.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'AY $academicYear',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldInk,
                      ),
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

  /// The due-date line, under the card rather than inside it: on the card it
  /// competed with the amount, and it is a note, not a headline.
  Widget _buildDueNote(AsyncValue<FeeSummary> feeSummaryAsync) {
    final feeSummary = feeSummaryAsync.valueOrNull;
    final settled = (feeSummary?.totalPending ?? 0) <= 0;
    final badge = _dueBadge(feeSummary?.nextDueDate);
    final text = settled
        ? 'Nothing pending for this academic year.'
        : badge?.helper;
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(settled ? 'tick-circle' : 'info-circle',
              size: 15, color: settled ? AppUi.paidInk : AppUi.inkMuted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: AppUi.inkMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Mobile: the School Bus card (only for a child who uses the bus)
  // ────────────────────────────────────────────────────────────────

  Widget _buildBusCard(BuildContext context) {
    final info = ref.watch(busInfoProvider).valueOrNull;
    if (info == null || !info.enabled || !info.enrolled) return const SizedBox.shrink();
    final trip = info.defaultTrip(DateTime.now());
    final live = trip?.live;
    final isLive = live != null && live.isLive(info.serverNow);
    final status = trip == null
        ? 'See the route and stops'
        : live == null
            ? '${trip.label} bus · location not shared yet'
            : isLive
                ? '${trip.label} bus · live now'
                : '${trip.label} bus · not sharing location now';
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(Routes.bus),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppUi.cardBox(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppUi.paidBg, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const AppIcon('bus', size: 22, color: AppUi.navy, bold: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('School Bus', style: AppFonts.body(size: 16, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Route ${info.routeCode}${info.routeName.isEmpty ? '' : ' · ${info.routeName}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(size: 13.5, color: AppUi.inkMuted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isLive ? AppColors.success : AppUi.inkFaint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.body(size: 13, weight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const AppIcon('arrow-right-3', size: 18, color: AppUi.inkFaint),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Mobile: the fee groups, one row each
  // ────────────────────────────────────────────────────────────────

  Widget _sectionHead(String title, String action, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppUi.ink),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Text(
              action,
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppUi.link),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeesSection(BuildContext context, List<FeeGroupSummary> groups,
      {bool isLoading = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHead(
            'Fees', 'View all', () => context.push(Routes.allPendingFees)),
        const SizedBox(height: 12),
        if (isLoading)
          Container(
            decoration: AppUi.cardBox(),
            child: Column(
              children: [
                for (int i = 0; i < 2; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppUi.lineSoft),
                  _feeRowSkeleton(),
                ],
              ],
            ),
          )
        else if (groups.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            decoration: AppUi.cardBox(),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppUi.paidBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child:
                        AppIcon('tick-circle', size: 20, color: AppUi.paidInk),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'No fees pending right now.',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppUi.inkMuted),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: AppUi.cardBox(),
            child: Column(
              children: [
                for (int i = 0; i < groups.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppUi.lineSoft),
                  _buildFeeGroupRow(context, groups[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFeeGroupRow(BuildContext context, FeeGroupSummary group) {
    final tint = AppUi.groupTint(group.groupName);
    final badge = _dueBadge(group.nearestDueDate);

    return InkWell(
      onTap: () => context.push(
          '${Routes.allPendingFees}?group=${Uri.encodeComponent(group.groupName)}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint[0],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AppIcon(AppUi.groupIcon(group.groupName),
                    size: 21, color: tint[1]),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _toTitleCase(group.groupName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppUi.ink),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: badge?.bg ?? AppUi.fill,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon('clock-1',
                            size: 12, color: badge?.ink ?? AppUi.inkMuted),
                        const SizedBox(width: 5),
                        Text(
                          badge?.label ?? 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: badge?.ink ?? AppUi.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${NumberFormat('#,##,###').format(group.totalAmount.toInt())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppUi.ink,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pay',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppUi.link),
                    ),
                    SizedBox(width: 3),
                    AppIcon('arrow-right-1', size: 13, color: AppUi.link),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _skelBox(double w, double h, {double radius = 6}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _feeRowSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE6DFCF),
        highlightColor: const Color(0xFFF3EDE0),
        child: Row(
          children: [
            _skelBox(44, 44, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skelBox(120, 14),
                  const SizedBox(height: 9),
                  _skelBox(84, 12),
                ],
              ),
            ),
            _skelBox(70, 18),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Mobile: recent payments
  // ────────────────────────────────────────────────────────────────

  Widget _buildRecentPaymentsSection(BuildContext context) {
    final recent = ref.watch(recentPaymentsProvider).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHead('Recent payments', 'History',
            () => context.go(Routes.paymentHistory)),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            decoration: AppUi.cardBox(),
            child: const Text(
              'No payments yet. Anything you pay shows up here.',
              style: TextStyle(fontSize: 14, color: AppUi.inkMuted),
            ),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: AppUi.cardBox(),
            child: Column(
              children: [
                for (int i = 0; i < recent.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppUi.lineSoft),
                  _buildRecentPaymentRow(context, recent[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRecentPaymentRow(BuildContext context, PaymentModel payment) {
    final paid = payment.paystatus == 'C';
    final when = payment.paydate ?? payment.createdat;

    return InkWell(
      onTap: () => context.push('/payment-history/${payment.payId}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: paid ? AppUi.paidBg : AppUi.failBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AppIcon(paid ? 'tick-circle' : 'close-circle',
                    size: 19, color: paid ? AppUi.paidInk : AppUi.failInk),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.paynumber ?? 'PAY/${payment.payId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppUi.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      paid ? 'Paid' : payment.statusText,
                      DateFormat('d MMM').format(when),
                      if (paid && (payment.paymethod ?? '').trim().isNotEmpty)
                        payment.paymethod!.trim(),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 12.5, color: AppUi.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '₹${NumberFormat('#,##,###').format(payment.transtotalamount.toInt())}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: paid ? AppUi.ink : AppUi.inkMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            const AppIcon('arrow-right-1', size: 16, color: AppUi.inkFaint),
          ],
        ),
      ),
    );
  }

  /// Desktop only: the Fees Breakup panel. Mobile renders [_buildFeesSection]
  /// instead -- a row per group rather than a carousel of cards.
  Widget _buildSpendingSection(BuildContext context, Map<String, double> feesByGroup, {bool isLoading = false}) {
    // ignore: unused_local_variable
    final categories = [
      {'name': 'School Fees', 'icon': 'book', 'color': const Color(0xFF0F6B63), 'iconBgColor': const Color(0xFFE1F0EC)},
      {'name': 'Van Fees', 'icon': 'bus', 'color': const Color(0xFFF0A43A), 'iconBgColor': const Color(0xFFFDF0DA)},
      {'name': 'Exam Fees', 'icon': 'task-square', 'color': const Color(0xFF2F7FB5), 'iconBgColor': const Color(0xFFE3EFF8)},
      // cardPurpleDark, not cardPurple: 'color' here is the ICON, and
      // cardPurple (#F0EEFF) is a background tint -- on the #F3E8FF circle it
      // drew the icon invisibly. Every other row pairs a saturated foreground
      // with a pale background; this one is now consistent with them.
      {'name': 'Other', 'icon': 'more', 'color': AppColors.cardPurpleDark, 'iconBgColor': const Color(0xFFEEE8F7)},
    ];

    // Arrear Fees first (must be cleared first), then by amount descending.
    final sortedEntries = feesByGroup.entries.toList()
      ..sort((a, b) {
        final aArr = a.key.toUpperCase().contains('ARREAR');
        final bArr = b.key.toUpperCase().contains('ARREAR');
        if (aArr != bArr) return aArr ? -1 : 1;
        return b.value.compareTo(a.value);
      });

    return Column(
      children: [
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
          ),
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
          color: hasColoredBg ? null : AppColors.cardBg(context),
          gradient: hasColoredBg ? AppColors.brandGradient : null,
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
                    color: AppColors.primary.withValues(alpha: 0.3),
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
                          : const Color(0xFFFDF0DA),
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
                                : const Color(0xFFF0A43A),
                          ),
                        ),
                        const SizedBox(width: 2),
                        AppIcon(
                          'arrow-up',
                          size: 12,
                          color: hasColoredBg
                              ? Colors.white
                              : const Color(0xFFF0A43A),
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
  /// Desktop only: the Fee Status table. Mobile shows the same information
  /// as fee-group rows in [_buildFeesSection].
  Widget _buildActivitySection(BuildContext context, List<FeeGroupSummary> overdueGroups, List<FeeGroupSummary> dueSoonGroups) {
    return DesktopContentCard(
      title: 'Fee Status',
      trailing: GestureDetector(
        onTap: () => context.push(Routes.allPendingFees),
        child: const Text(
          'View all',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textLink,
          ),
        ),
      ),
      hasPadding: false,
      child: _buildDesktopFeeTable(context, overdueGroups, dueSoonGroups,
          overdueGroups.isNotEmpty, dueSoonGroups.isNotEmpty),
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
      groupBg = const Color(0xFFFDF0DA);
      groupIconColor = const Color(0xFFF0A43A);
    } else if (lowerName.contains('hostel')) {
      groupIcon = 'home-2';
      groupBg = const Color(0xFFE1F0EC);
      groupIconColor = const Color(0xFF0F6B63);
    } else if (lowerName.contains('exam')) {
      groupIcon = 'task-square';
      groupBg = const Color(0xFFE3EFF8);
      groupIconColor = const Color(0xFF2F7FB5);
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

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Map<String, dynamic> _getIconForFeeGroup(String groupName) {
    final lowerName = groupName.toLowerCase();

    if (lowerName.contains('arrear')) {
      // Virtual "Arrear Fees" group — deep-orange attention tone, matching
      // FeeGroupUtils.arrearStyle and the desktop's orange arrear badge.
      return {
        'icon': 'clock-1',
        'color': const Color(0xFFB7701A), // orange-600
        'iconBgColor': const Color(0xFFFDF0DA), // orange-100
      };
    } else if (lowerName.contains('school') || lowerName.contains('tuition')) {
      return {
        'icon': 'book',
        'color': const Color(0xFF0F6B63),
        'iconBgColor': const Color(0xFFE1F0EC),
      };
    } else if (lowerName.contains('van') || lowerName.contains('bus') || lowerName.contains('transport')) {
      return {
        'icon': 'bus',
        'color': const Color(0xFFF0A43A),
        'iconBgColor': const Color(0xFFFDF0DA),
      };
    } else if (lowerName.contains('hostel')) {
      return {
        'icon': 'home-2',
        'color': const Color(0xFF0F6B63),
        'iconBgColor': const Color(0xFFE1F0EC),
      };
    } else if (lowerName.contains('exam') || lowerName.contains('test')) {
      return {
        'icon': 'task-square',
        'color': const Color(0xFF2F7FB5),
        'iconBgColor': const Color(0xFFE3EFF8),
      };
    } else {
      // The catch-all group (e.g. "College Fees"). cardPurpleDark is the
      // foreground; cardPurple is the background tint and left the icon
      // invisible on the pale circle.
      return {
        'icon': 'receipt',
        'color': AppColors.cardPurpleDark,
        'iconBgColor': const Color(0xFFEEE8F7),
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
