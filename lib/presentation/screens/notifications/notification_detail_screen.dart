import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/fee_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/app_action_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/app_icon_circle_button.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';
import '../../../core/constants/app_ui.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String notificationId;
  final NotificationModel? notification;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    this.notification,
  });

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark as read when viewing
    if (widget.notification != null && !widget.notification!.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(notificationActionsProvider.notifier)
            .markAsRead(widget.notificationId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;

    if (notification == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: _buildAppBar(context),
        body: const Center(
          child: Text('Notification not found'),
        ),
      );
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
      toolbar: BreadcrumbBar(
        parentLabel: 'Notifications',
        parentRoute: Routes.notifications,
        currentLabel: notification.title,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: context.isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (context.isDesktop) ...[
                _buildDesktopGreetingBanner(context, notification),
                const SizedBox(height: 18),
                _buildDesktopTitle(context, notification),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 24),
              // Main card — combines icon, badge, title, time, message
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top colored banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _getBannerColor(notification.type),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          _buildNotificationIcon(notification.type),
                          const SizedBox(width: 16),
                          // Title + Badge
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTypeBadge(notification.type),
                                const SizedBox(height: 8),
                                Text(
                                  notification.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF17232B),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Body content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date & Time row
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3EDE0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(child: AppIcon('clock', size: 16, color: Color(0xFF8A979D))),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatDateTime(notification.createdAt),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8A979D),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Divider
                          Container(height: 1, color: const Color(0xFFEFE9DC)),
                          const SizedBox(height: 20),
                          // Message
                          Text(
                            notification.body,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF17232B),
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Button (if applicable)
              if (_hasAction(notification.type))
                _buildActionButton(notification),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopGreetingBanner(
      BuildContext context, NotificationModel notification) {
    final isUnread = !notification.isRead;
    final message = isUnread
        ? "You're viewing a new notification."
        : 'Notification details.';
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

  Widget _buildDesktopTitle(
      BuildContext context, NotificationModel notification) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final firstName =
        selectedStudent?.name.trim().split(' ').first ?? 'Student';
    final admissionNo = selectedStudent?.admissionNumber ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$firstName's Notification",
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Back Button — amber circle + state handling
          AppIconCircleButton(
            onPressed: () => context.pop(),
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
              'Notification',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryC(context),
              ),
            ),
          ),
          // Student chip (desktop) or placeholder (mobile)
          if (context.isDesktop)
            _buildStudentChip(context)
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildStudentChip(BuildContext context) {
    final student = ref.watch(selectedStudentProvider);
    if (student == null) return const SizedBox(width: 44);
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.scaffoldBg(context),
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: AppIcon(
          'arrow-left-1',
          size: 18,
          color: AppColors.textPrimaryC(context),
        ),
      ),
      title: Text(
        'Notification',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryC(context),
        ),
      ),
      centerTitle: true,
    );
  }

  Color _getBannerColor(NotificationType type) {
    switch (type) {
      case NotificationType.feeReminder:
      case NotificationType.dueDateApproaching:
        return AppColors.cardYellow; // #FFFBE6
      case NotificationType.paymentSuccess:
        return AppColors.cardGreen; // #E6F9F0
      case NotificationType.paymentFailed:
      case NotificationType.alert:
        return AppColors.cardRose; // #FFF1F2
      case NotificationType.announcement:
        return AppColors.cardBlue; // #E8F4FD
      default:
        return AppColors.gray100;
    }
  }

  Widget _buildNotificationIcon(NotificationType type) {
    String icon;
    Color bgColor;
    Color iconColor;

    switch (type) {
      case NotificationType.feeReminder:
      case NotificationType.dueDateApproaching:
        icon = 'notification';
        bgColor = AppColors.warningLight;
        iconColor = AppColors.warningDark;
        break;
      case NotificationType.paymentSuccess:
        icon = 'tick-circle';
        bgColor = AppColors.successLight;
        iconColor = AppColors.successDark;
        break;
      case NotificationType.paymentFailed:
        icon = 'close-circle';
        bgColor = AppColors.errorLight;
        iconColor = AppColors.errorDark;
        break;
      case NotificationType.alert:
        icon = 'warning-2';
        bgColor = AppColors.errorLight;
        iconColor = AppColors.errorDark;
        break;
      case NotificationType.announcement:
        icon = 'message';
        bgColor = AppColors.infoLight;
        iconColor = AppColors.infoDark;
        break;
      default:
        icon = 'notification';
        bgColor = AppColors.gray100;
        iconColor = AppColors.gray500;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AppIcon(
          icon,
          size: 28,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(NotificationType type) {
    String label;
    Color bgColor;
    Color textColor;

    switch (type) {
      case NotificationType.feeReminder:
      case NotificationType.dueDateApproaching:
        label = 'Fee Reminder';
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        break;
      case NotificationType.paymentSuccess:
        label = 'Payment Success';
        bgColor = AppColors.successLight;
        textColor = AppColors.successDark;
        break;
      case NotificationType.paymentFailed:
        label = 'Payment Failed';
        bgColor = AppColors.errorLight;
        textColor = AppColors.errorDark;
        break;
      case NotificationType.alert:
        label = 'Alert';
        bgColor = AppColors.errorLight;
        textColor = AppColors.errorDark;
        break;
      case NotificationType.announcement:
        label = 'Announcement';
        bgColor = AppColors.infoLight;
        textColor = AppColors.infoDark;
        break;
      default:
        label = 'Notification';
        bgColor = AppColors.gray100;
        textColor = AppColors.gray600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (notificationDate == today) {
      dateStr = 'Today';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      dateStr = 'Yesterday';
    } else {
      dateStr = DateFormat('d MMMM yyyy').format(dateTime);
    }

    final timeStr = DateFormat('h:mm a').format(dateTime);
    return '$dateStr at $timeStr';
  }

  Future<void> _handleRetryPayment(dynamic payId) async {
    if (payId == null) {
      context.push('/cart');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Get dem_ids from paymentdetails for this payment
      final payDetails = await SupabaseService.fromSchema('paymentdetails')
          .select('dem_id')
          .eq('pay_id', payId);

      final demIds = (payDetails as List)
          .map((d) => d['dem_id'] is int
              ? d['dem_id'] as int
              : int.parse(d['dem_id'].toString()))
          .toList();

      if (demIds.isEmpty) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fee details found for this payment'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 2. Fetch fresh feedemand records
      final fees = await SupabaseService.fromSchema('feedemand')
          .select('*')
          .inFilter('dem_id', demIds)
          .eq('activestatus', 1);

      final feeModels = (await SupabaseService.withFeeTypes(fees))
          .map((f) => FeeModel.fromJson(f))
          .toList();

      // 3. Filter to only unpaid fees
      final unpaidFees = feeModels
          .where((f) => f.balancedue > 0 && f.paidstatus != 'P')
          .toList();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (unpaidFees.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: const AppIcon('tick-circle',
                color: Color(0xFF0F6B63), size: 48),
            title: const Text('Already Paid'),
            content: const Text(
                'All fees from this payment have already been paid.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final cartNotifier = ref.read(cartProvider.notifier);
        cartNotifier.clearCart();
        cartNotifier.addFees(unpaidFees);

        if (mounted) {
          context.go(Routes.cart);
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePayFees(List<dynamic> demIds,
      {bool isUpcoming = false}) async {
    // Block upcoming fee payment if overdue fees exist
    if (isUpcoming) {
      final notifications =
          ref.read(notificationsProvider).valueOrNull ?? [];
      final hasOverdue =
          notifications.any((n) => n.id == 'fee_overdue_summary');
      if (hasOverdue) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please clear your overdue fees first before paying upcoming fees.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    if (demIds.isEmpty) {
      context.go(Routes.cart);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fees = await SupabaseService.fromSchema('feedemand')
          .select('*')
          .inFilter('dem_id', demIds)
          .eq('activestatus', 1);

      final feeModels = (await SupabaseService.withFeeTypes(fees))
          .map((f) => FeeModel.fromJson(f))
          .toList();
      final unpaidFees = feeModels
          .where((f) => f.balancedue > 0 && f.paidstatus != 'P')
          .toList();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (unpaidFees.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: const AppIcon('tick-circle',
                color: Color(0xFF0F6B63), size: 48),
            title: const Text('All Paid'),
            content:
                const Text('All fees have already been paid. Great job!'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final cartNotifier = ref.read(cartProvider.notifier);
        cartNotifier.clearCart();
        cartNotifier.addFees(unpaidFees);
        if (mounted) context.go(Routes.cart);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _hasAction(NotificationType type) {
    return type == NotificationType.feeReminder ||
        type == NotificationType.dueDateApproaching ||
        type == NotificationType.paymentSuccess ||
        type == NotificationType.paymentFailed;
  }

  Widget _buildActionButton(NotificationModel notification) {
    String buttonText;
    String buttonIcon;
    Color buttonColor;
    VoidCallback onTap;

    // Extract pay_id from notification data for navigation
    final payId = notification.data?['pay_id'];

    switch (notification.type) {
      case NotificationType.feeReminder:
      case NotificationType.dueDateApproaching:
        buttonText = 'Pay Now';
        buttonIcon = 'wallet-3';
        buttonColor = const Color(0xFF121212);
        final demIds = notification.data?['dem_ids'] as List<dynamic>? ?? [];
        onTap = () => _handlePayFees(
              demIds,
              isUpcoming: notification.id == 'fee_upcoming_summary',
            );
        break;
      case NotificationType.paymentSuccess:
        // Navigate to transaction details for the successful payment.
        // `payId` is the int id of the payment row.
        if (payId == null) return const SizedBox.shrink();
        return AppActionButton(
          onPressed: () =>
              context.push('${Routes.transactionDetails}/$payId'),
          label: 'View Transaction',
          borderRadius: 16,
          trailing: const AppIcon(
            'arrow-right-1',
            size: 20,
            color: Colors.white,
          ),
        );
      case NotificationType.paymentFailed:
        buttonText = 'Retry Payment';
        buttonIcon = 'refresh';
        buttonColor = const Color(0xFFC8453A);
        onTap = () => _handleRetryPayment(payId);
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(buttonIcon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
