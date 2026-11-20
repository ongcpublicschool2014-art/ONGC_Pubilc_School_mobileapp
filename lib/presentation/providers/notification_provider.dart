import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/notification_model.dart';
import 'student_provider.dart';

final _currencyFmt = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Converts a `notification` table row into a NotificationModel.
NotificationModel _dbNotificationToModel(Map<String, dynamic> row) {
  final notiId = row['noti_id'].toString();
  final title = row['notititle'] as String? ?? '';
  final body = row['notibody'] as String? ?? '';
  final notiType = row['notitype'] as String? ?? 'general';
  final isRead = (row['isread'] as int?) == 1;
  // `createdat` is a UTC timestamptz — convert to local (IST) so the displayed
  // time matches when the admin actually posted it, not the UTC wall clock.
  final createdAt = row['createdat'] != null
      ? DateTime.parse(row['createdat']).toLocal()
      : DateTime.now();

  NotificationType type;
  switch (notiType) {
    case 'notice':
    case 'announcement':
      type = NotificationType.announcement;
      break;
    case 'alert':
      type = NotificationType.alert;
      break;
    case 'fee_reminder':
      type = NotificationType.feeReminder;
      break;
    default:
      type = NotificationType.general;
  }

  return NotificationModel(
    id: 'noti_$notiId',
    schoolId: row['ins_id']?.toString() ?? '',
    parentId: '',
    studentId: row['stu_id']?.toString(),
    title: title,
    message: body,
    type: type,
    isRead: isRead,
    createdAt: createdAt,
  );
}

/// Converts a payment record into a NotificationModel.
/// Read status comes from [notification_read] column in the payment table.
NotificationModel _paymentToNotification(Map<String, dynamic> payment) {
  final payId = payment['pay_id'].toString();
  final notificationId = 'pay_$payId';
  final amount = (payment['transtotalamount'] as num?)?.toDouble() ?? 0;
  final status = payment['paystatus'] as String?;
  final paydate = payment['paydate'] != null
      ? DateTime.parse(payment['paydate']).toLocal()
      : DateTime.parse(payment['createdat']).toLocal();
  final paynumber = payment['paynumber'] ?? 'PAY${payId.padLeft(6, '0')}';
  final isRead = payment['notification_read'] as bool? ?? false;
  final formattedAmount = _currencyFmt.format(amount);

  String title;
  String message;
  NotificationType type;

  switch (status) {
    case 'C':
      title = 'Payment Successful';
      message =
          'Your payment of $formattedAmount ($paynumber) was completed successfully.';
      type = NotificationType.paymentSuccess;
      break;
    case 'F':
      title = 'Payment Failed';
      message =
          'Your payment of $formattedAmount ($paynumber) has failed. Please try again.';
      type = NotificationType.paymentFailed;
      break;
    case 'R':
      title = 'Payment Refunded';
      message =
          'Your payment of $formattedAmount ($paynumber) has been refunded.';
      type = NotificationType.alert;
      break;
    default:
      title = 'Payment Initiated';
      message =
          'Your payment of $formattedAmount ($paynumber) has been initiated.';
      type = NotificationType.general;
      break;
  }

  return NotificationModel(
    id: notificationId,
    schoolId: payment['ins_id']?.toString() ?? '',
    parentId: '',
    studentId: payment['stu_id']?.toString(),
    title: title,
    message: message,
    type: type,
    data: {'pay_id': payment['pay_id']},
    isRead: isRead,
    createdAt: paydate,
  );
}


final notificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final selectedStudent = ref.watch(selectedStudentProvider);

  if (selectedStudent == null) return [];

  List<NotificationModel> notifications = [];

  // 1. Fetch payment notifications (success / failed / refunded)
  try {
    final response = await SupabaseService.fromSchema('payment')
        .select()
        .eq('stu_id', selectedStudent.stuId)
        .eq('activestatus', 1)
        .neq('paystatus', 'I')
        .order('createdat', ascending: false)
        .limit(50);

    notifications = (response as List<dynamic>)
        .map((e) => _paymentToNotification(e as Map<String, dynamic>))
        .toList();
  } catch (_) {}

  // 2. Fetch school notifications from the `notification` table
  try {
    final notiResponse = await SupabaseService.fromSchema('notification')
        .select()
        .eq('stu_id', selectedStudent.stuId)
        .eq('activestatus', 1)
        .order('createdat', ascending: false)
        .limit(50);

    final dbNotifications = (notiResponse as List<dynamic>)
        .map((e) => _dbNotificationToModel(e as Map<String, dynamic>))
        .toList();
    notifications.addAll(dbNotifications);
  } catch (_) {}

  // 3. Fetch fee reminders and group into summary cards:
  //    - One "Fee Overdue" card  for all overdue unpaid fees
  //    - One "Upcoming Fees"  card for fees due within 10 days
  //    Both repeat daily until fees are paid.
  try {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tenDaysLater = now.add(const Duration(days: 10));

    final feeResponse = await SupabaseService.fromSchema('feedemand')
        .select()
        .eq('stu_id', selectedStudent.stuId)
        .eq('activestatus', 1)
        .neq('paidstatus', 'P')
        .not('duedate', 'is', null)
        .lte('duedate', _dateStr(tenDaysLater))
        .gt('balancedue', 0);

    final fees = feeResponse as List<dynamic>;

    // Split into overdue vs upcoming
    final overdueFees = fees.where((f) {
      final due = DateTime.parse(f['duedate']);
      return DateTime(due.year, due.month, due.day).isBefore(today);
    }).toList();

    final upcomingFees = fees.where((f) {
      final due = DateTime.parse(f['duedate']);
      return !DateTime(due.year, due.month, due.day).isBefore(today);
    }).toList();

    // Overdue summary card
    if (overdueFees.isNotEmpty) {
      final totalOverdue = overdueFees.fold(
          0.0, (sum, f) => sum + ((f['balancedue'] as num?)?.toDouble() ?? 0));
      final studentName = selectedStudent.name;
      notifications.add(NotificationModel(
        id: 'fee_overdue_summary',
        schoolId: overdueFees.first['ins_id']?.toString() ?? '',
        parentId: '',
        studentId: overdueFees.first['stu_id']?.toString(),
        title: 'Fee Overdue',
        message:
            '$studentName has an outstanding balance of ${_currencyFmt.format(totalOverdue)}. Please pay immediately.',
        type: NotificationType.feeReminder,
        data: {'dem_ids': overdueFees.map((f) => f['dem_id']).toList()},
        isRead: false,
        createdAt: DateTime.now(),
      ));
    }

    // Upcoming summary card
    if (upcomingFees.isNotEmpty) {
      final totalUpcoming = upcomingFees.fold(
          0.0, (sum, f) => sum + ((f['balancedue'] as num?)?.toDouble() ?? 0));
      // Find the nearest due date for the message
      final nearestDue = upcomingFees
          .map((f) => DateTime.parse(f['duedate']))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final daysLeft = DateTime(nearestDue.year, nearestDue.month, nearestDue.day)
          .difference(today)
          .inDays;
      final daysText = daysLeft == 0
          ? 'today'
          : daysLeft == 1
              ? 'tomorrow'
              : 'in $daysLeft days';
      final studentName = selectedStudent.name;
      notifications.add(NotificationModel(
        id: 'fee_upcoming_summary',
        schoolId: upcomingFees.first['ins_id']?.toString() ?? '',
        parentId: '',
        studentId: upcomingFees.first['stu_id']?.toString(),
        title: 'Upcoming Fee Due',
        message:
            '$studentName has a fee of ${_currencyFmt.format(totalUpcoming)} due $daysText. Please pay within the due date.',
        type: NotificationType.dueDateApproaching,
        data: {'dem_ids': upcomingFees.map((f) => f['dem_id']).toList()},
        isRead: false,
        // 1 second behind overdue so overdue always sorts first
        createdAt: DateTime.now().subtract(const Duration(seconds: 1)),
      ));
    }
  } catch (_) {}

  // Sort all by date descending — fee reminders appear under "Today", payments under their actual dates
  notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return notifications;
});

/// Unread notification count for badge display.
/// Fee reminders always count as unread until paid.
final notificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  NotificationNotifier(this._ref) : super(const AsyncValue.data(null));

  /// payment is a money table: the app has no UPDATE grant on it, so updating
  /// notification_read directly was refused (42501) and the read state never
  /// saved. The SECURITY DEFINER RPC sets only that flag, and only on the
  /// selected student's own payments.
  Future<void> _markPaymentsRead(List<int> payIds) async {
    final student = _ref.read(selectedStudentProvider);
    if (student == null || payIds.isEmpty) return;
    await SupabaseService.client.rpc('mark_payment_notifications_read', params: {
      'p_ins_id': student.insId,
      'p_stu_id': student.stuId,
      'p_pay_ids': payIds,
    });
  }

  /// Marks a notification as read.
  /// - `pay_*` → updates `notification_read` in `payment` table
  /// - `noti_*` → updates `isread` in `notification` table
  /// - Fee notifications (`fee_*`) are skipped — they stay until paid.
  Future<void> markAsRead(String notificationId) async {
    try {
      if (notificationId.startsWith('pay_')) {
        final payId = int.tryParse(notificationId.replaceFirst('pay_', ''));
        if (payId == null) return;
        await _markPaymentsRead([payId]);
      } else if (notificationId.startsWith('noti_')) {
        final notiId = int.tryParse(notificationId.replaceFirst('noti_', ''));
        if (notiId == null) return;
        await SupabaseService.fromSchema('notification')
            .update({'isread': 1}).eq('noti_id', notiId);
      } else {
        return; // fee_* notifications — skip
      }
      _ref.invalidate(notificationsProvider);
    } catch (_) {}
    state = const AsyncValue.data(null);
  }

  /// Marks all payment and notification table notifications as read.
  /// Fee reminders are skipped — they stay unread until the fee is paid.
  Future<void> markAllAsRead() async {
    final notifications = _ref.read(notificationsProvider).valueOrNull ?? [];

    // Mark payment notifications as read
    final unreadPayIds = notifications
        .where((n) => !n.isRead && n.id.startsWith('pay_'))
        .map((n) => int.tryParse(n.id.replaceFirst('pay_', '')))
        .whereType<int>()
        .toList();

    if (unreadPayIds.isNotEmpty) {
      try {
        await _markPaymentsRead(unreadPayIds);
      } catch (_) {}
    }

    // Mark notification table records as read
    final unreadNotiIds = notifications
        .where((n) => !n.isRead && n.id.startsWith('noti_'))
        .map((n) => int.tryParse(n.id.replaceFirst('noti_', '')))
        .whereType<int>()
        .toList();

    if (unreadNotiIds.isNotEmpty) {
      try {
        await SupabaseService.fromSchema('notification')
            .update({'isread': 1}).inFilter('noti_id', unreadNotiIds);
      } catch (_) {}
    }

    _ref.invalidate(notificationsProvider);
    state = const AsyncValue.data(null);
  }
}

final notificationActionsProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  return NotificationNotifier(ref);
});

/// Supabase Realtime listener for the `notification` table.
/// Subscribes when a student is selected; shows a local push notification
/// on INSERT and refreshes the notifications list.
final notificationRealtimeProvider = Provider.autoDispose<void>((ref) {
  final selectedStudent = ref.watch(selectedStudentProvider);

  if (selectedStudent == null) return;

  final channel = SupabaseService.client
      .channel('notification_realtime_${selectedStudent.stuId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: SupabaseService.currentSchema ?? 'public',
        table: 'notification',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'stu_id',
          value: selectedStudent.stuId,
        ),
        callback: (payload) {
          final newRow = payload.newRecord;
          if (newRow.isEmpty) return;

          // Skip inserts that arrive already-inactive (activestatus != 1) so
          // admin-created draft/archived notices don't push or refresh.
          final activestatus = newRow['activestatus'];
          final isActive = activestatus == 1 || activestatus == '1';
          if (!isActive) return;

          final title = newRow['notititle'] as String? ?? 'New Notification';
          final body = newRow['notibody'] as String? ?? '';
          final notiId = newRow['noti_id'] as int? ?? DateTime.now().millisecondsSinceEpoch;

          // Show local push notification (mobile only)
          if (!kIsWeb) {
            NotificationService.showInstantNotification(
              id: notiId % 100000, // keep ID in safe range
              title: title,
              body: body,
            );
          }

          // Refresh the notifications list
          ref.invalidate(notificationsProvider);
        },
      )
      .subscribe();

  ref.onDispose(() {
    SupabaseService.client.removeChannel(channel);
  });
});
