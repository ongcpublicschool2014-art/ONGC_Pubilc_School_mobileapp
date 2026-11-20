import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_ui.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/fee_provider.dart';
import '../../widgets/common/app_icon.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const Color _cardBg = Color(0xFFFFFDF8);
  static const Color _textDark = Color(0xFF17232B);
  static const Color _textMedium = Color(0xFF4A5A63);
  static const Color _textLight = Color(0xFF4A5A63);

  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor:
          context.isDesktop ? AppColors.scaffoldBg(context) : AppUi.pageBg,
      body: Column(
        children: [
            // Desktop: no header | Mobile: the page's own title bar
            if (!context.isDesktop)
              Container(
                color: _cardBg,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: _cardBg,
                      border: Border(bottom: BorderSide(color: AppUi.line)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        _buildHeader(context),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            // Fee reminder banners
            _buildFeeReminderBanners(context, ref),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (notifications) {
                  // Filter out fee summary cards — they're shown as banners above
                  final regularNotifications = notifications
                      .where((n) => n.id != 'fee_overdue_summary' && n.id != 'fee_upcoming_summary')
                      .toList();

                  if (regularNotifications.isEmpty) {
                    return _buildEmptyState();
                  }
                  const int pageSize = 10;
                  final totalPages = (regularNotifications.length / pageSize).ceil();
                  final paged = regularNotifications
                      .skip(_currentPage * pageSize)
                      .take(pageSize)
                      .toList();

                  if (context.isDesktop) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDesktopGreetingBanner(
                              context, regularNotifications),
                          const SizedBox(height: 18),
                          _buildDesktopTitle(context),
                          const SizedBox(height: 20),
                          _buildDesktopStatCards(
                              context, regularNotifications),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardBg(context),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppColors.cardShadow(context),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                _buildDesktopNotificationTable(paged),
                                _buildPaginationControls(totalPages),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Mobile: show all notifications in a scrollable list (no pagination)
                  final groupedNotifications = _groupNotificationsByDate(regularNotifications);
                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
                    itemCount: groupedNotifications.length,
                    itemBuilder: (context, index) {
                      final group = groupedNotifications[index];
                      return _buildNotificationGroup(group);
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildDesktopGreetingBanner(
      BuildContext context, List<NotificationModel> notifications) {
    final unread = notifications.where((n) => !n.isRead).length;
    final hasUnread = unread > 0;
    final message = hasUnread
        ? "You have $unread unread ${unread == 1 ? 'notification' : 'notifications'}."
        : "All caught up — no new notifications.";
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
        selectedStudent?.name.trim().split(' ').first ?? 'Student';
    final admissionNo = selectedStudent?.admissionNumber ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$firstName's Notifications",
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
      BuildContext context, List<NotificationModel> notifications) {
    final unread = notifications.where((n) => !n.isRead).length;
    final read = notifications.length - unread;
    final today = DateTime.now();
    final todayCount = notifications.where((n) {
      final d = n.createdAt;
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).length;
    return Row(
      children: [
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Total',
            value: '${notifications.length}',
            icon: 'notification',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Unread',
            value: '$unread',
            icon: 'message',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Read',
            value: '$read',
            icon: 'tick-circle',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Today',
            value: '$todayCount',
            icon: 'calendar',
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

  Widget _buildDesktopNotificationTable(List<NotificationModel> notifications) {
    const headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.5,
    );
    return Column(
      children: [
        // Header row — green band with white labels (matches Fee Status)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AppColors.primary,
          child: Row(
            children: const [
              SizedBox(width: 60), // icon (48) + gap (12)
              Expanded(flex: 3, child: Text('Title', style: headerStyle)),
              Expanded(flex: 4, child: Text('Message', style: headerStyle)),
              SizedBox(width: 140, child: Text('Date', style: headerStyle)),
              SizedBox(width: 36),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.borderC(context)),
        // Data rows
        ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: AppColors.borderC(context)),
          itemBuilder: (context, index) =>
              _buildDesktopNotificationRow(notifications[index]),
        ),
      ],
    );
  }

  Widget _buildDesktopNotificationRow(NotificationModel notification) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: () async {
        if (isUnread) {
          ref.read(notificationActionsProvider.notifier).markAsRead(notification.id);
        }
        await context.push('/notifications/${notification.id}', extra: notification);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isUnread
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        child: Row(
          children: [
            _buildNotificationIcon(notification.type, isUnread),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                notification.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimaryC(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                notification.body,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryC(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                _getTimestamp(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHintC(context),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isUnread) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  AppIcon(
                    'arrow-right-1',
                    size: 14,
                    color: AppColors.textHintC(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            icon: 'arrow-left-1',
            enabled: _currentPage > 0,
            onTap: () => setState(() => _currentPage--),
          ),
          const SizedBox(width: 8),
          for (int i = 0; i < totalPages; i++) ...[
            if (i == 0 ||
                i == totalPages - 1 ||
                (i >= _currentPage - 1 && i <= _currentPage + 1))
              GestureDetector(
                onTap: () => setState(() => _currentPage = i),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == _currentPage ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: i != _currentPage
                        ? Border.all(color: AppColors.borderC(context))
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: i == _currentPage
                            ? Colors.white
                            : AppColors.textSecondaryC(context),
                      ),
                    ),
                  ),
                ),
              )
            else if ((i == 1 && _currentPage > 2) ||
                (i == totalPages - 2 && _currentPage < totalPages - 3))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '…',
                  style: TextStyle(color: AppColors.textHintC(context)),
                ),
              ),
          ],
          const SizedBox(width: 8),
          _buildPageButton(
            icon: 'arrow-right-1',
            enabled: _currentPage < totalPages - 1,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required String icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderC(context)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: AppIcon(
            icon,
            size: 20,
            color: enabled
                ? AppColors.textPrimaryC(context)
                : AppColors.textHintC(context),
          ),
        ),
      ),
    );
  }

  List<_NotificationGroup> _groupNotificationsByDate(List<NotificationModel> notifications) {
    final Map<String, List<NotificationModel>> grouped = {};
    for (final notification in notifications) {
      final dateKey = _getDateGroup(notification.createdAt);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(notification);
    }
    return grouped.entries
        .map((e) => _NotificationGroup(date: e.key, notifications: e.value))
        .toList();
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return _formatDate(date);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildHeader(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = (notificationsAsync.valueOrNull ?? [])
        .where((n) => !n.isRead)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Alerts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppUi.ink,
                letterSpacing: -0.4,
              ),
            ),
          ),
          // Clearing the lot is the thing most people want from this screen;
          // it used to take opening each alert in turn.
          if (unread > 0)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(notificationActionsProvider.notifier).markAllAsRead(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppUi.link),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeeReminderBanners(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final notifications = notificationsAsync.valueOrNull ?? [];

    final overdueNotification = notifications
        .where((n) => n.id == 'fee_overdue_summary')
        .toList();
    final upcomingNotification = notifications
        .where((n) => n.id == 'fee_upcoming_summary')
        .toList();

    if (overdueNotification.isEmpty && upcomingNotification.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? 0 : 20,
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (overdueNotification.isNotEmpty)
            _buildReminderBanner(
              context: context,
              icon: 'warning-2',
              iconBgColor: AppColors.errorLight,
              iconColor: AppColors.error,
              borderColor: AppColors.error.withValues(alpha: 0.3),
              bgColor: AppColors.errorLight.withValues(alpha: 0.5),
              title: overdueNotification.first.title,
              message: overdueNotification.first.body,
              actionLabel: 'Pay Now',
              onAction: () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final overdueFees = ref.read(pendingFeesProvider)
                    .where((f) => f.dueDate.isBefore(today))
                    .toList();
                if (overdueFees.isNotEmpty) {
                  ref.read(cartProvider.notifier).addFees(overdueFees);
                }
                context.go(Routes.cart);
              },
            ),
          if (overdueNotification.isNotEmpty && upcomingNotification.isNotEmpty)
            const SizedBox(height: 10),
          if (upcomingNotification.isNotEmpty)
            _buildReminderBanner(
              context: context,
              icon: 'clock',
              iconBgColor: AppColors.warningLight,
              iconColor: AppColors.warningDark,
              borderColor: AppColors.warning.withValues(alpha: 0.3),
              bgColor: AppColors.warningLight.withValues(alpha: 0.5),
              title: upcomingNotification.first.title,
              message: upcomingNotification.first.body,
              actionLabel: 'View Fees',
              onAction: () => context.go(Routes.home),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildReminderBanner({
    required BuildContext context,
    required String icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color borderColor,
    required Color bgColor,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    // The action goes UNDER the message, full width. Pinned to the right of a
    // two-line message it squeezed the text into a column three words wide.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppUi.radius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: AppIcon(icon, size: 22, color: iconColor)),
          ),
          const SizedBox(width: 12),
          // Full-width message column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryC(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onAction,
            child: Container(
              width: double.infinity,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppUi.navy,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationGroup(_NotificationGroup group) {
    // A day's alerts share one card. Each alert as its own floating card made
    // a quiet day and a busy one look the same from a distance.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10, left: 2),
          child: Text(
            group.date,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppUi.inkMuted,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: AppUi.cardBox(),
          child: Column(
            children: [
              for (int i = 0; i < group.notifications.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Divider(height: 1, color: AppUi.lineSoft),
                  ),
                _buildNotificationCard(group.notifications[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: () async {
        if (isUnread) {
          ref.read(notificationActionsProvider.notifier).markAsRead(notification.id);
        }
        await context.push('/notifications/${notification.id}', extra: notification);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        // Unread is carried by a faint wash inside the shared card, since the
        // row no longer has a border of its own to tint.
        color: isUnread ? AppUi.link.withValues(alpha: 0.04) : AppUi.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification.type, isUnread),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: AppUi.ink,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: AppUi.link,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _textMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTimestamp(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textLight,
                        ),
                      ),
                      const AppIcon(
                        'arrow-right-1',
                        size: 14,
                        color: _textLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type, bool isUnread) {
    final String icon = switch (type) {
      NotificationType.feeReminder ||
      NotificationType.dueDateApproaching =>
        'notification',
      NotificationType.paymentSuccess => 'tick-circle',
      NotificationType.paymentFailed ||
      NotificationType.alert =>
        'warning-2',
      NotificationType.newFeeAdded => 'add-circle',
      NotificationType.announcement => 'message',
      NotificationType.general => 'info-circle',
    };

    // Tinted by what the alert says, not one navy disc for everything: a
    // received payment and a failed one should not look identical at a glance.
    final (Color bg, Color fg) = switch (type) {
      NotificationType.paymentSuccess => (AppUi.paidBg, AppUi.paidInk),
      NotificationType.paymentFailed || NotificationType.alert => (
          AppUi.failBg,
          AppUi.failInk
        ),
      NotificationType.feeReminder || NotificationType.dueDateApproaching => (
          AppUi.dueBg,
          AppUi.dueInk
        ),
      _ => (const Color(0xFFE1F0EC), AppUi.navy),
    };

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: AppIcon(icon, size: 17, color: fg)),
    );
  }

  String _getTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return _formatDate(date);
    }
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
              child: Center(
                child: AppIcon(
                  'notification',
                  size: 48,
                  color: AppColors.cardPurpleDark,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.isDesktop ? AppColors.textPrimaryC(context) : _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! Check back later for updates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.isDesktop ? AppColors.textSecondaryC(context) : _textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _NotificationGroup {
  final String date;
  final List<NotificationModel> notifications;

  _NotificationGroup({required this.date, required this.notifications});
}
