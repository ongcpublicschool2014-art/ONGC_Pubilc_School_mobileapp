import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

const int _notificationId = 1001;
const String _channelKey = 'overdue_fee_reminder';
const String _realtimeChannelKey = 'realtime_notifications';

class NotificationService {
  /// Initialize awesome_notifications with the app's notification channels.
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // null = use default app icon
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'Fee Overdue Reminders',
          channelDescription: 'Daily reminders for overdue school fees',
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          defaultPrivacy: NotificationPrivacy.Public,
          defaultColor: Colors.red,
          ledColor: Colors.red,
        ),
        NotificationChannel(
          channelKey: _realtimeChannelKey,
          channelName: 'School Notifications',
          channelDescription: 'Notices and announcements from your school',
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          defaultPrivacy: NotificationPrivacy.Public,
          defaultColor: const Color(0xFF0F6B63),
          ledColor: const Color(0xFF0F6B63),
        ),
      ],
    );
  }

  /// Request notification permission (Android 13+).
  static Future<void> requestPermission() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  /// Schedule a daily 7:00 AM repeating notification using local time directly.
  /// No timezone package needed — awesome_notifications handles it natively.
  static Future<void> scheduleDailyReminder() async {
    await AwesomeNotifications().cancel(_notificationId);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _notificationId,
        channelKey: _channelKey,
        title: 'School Fee Reminder',
        body: 'You have outstanding school fees. Tap to view and pay.',
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        hour: 7,
        minute: 0,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  /// Show an instant push notification (used for real-time Supabase notifications).
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: _realtimeChannelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        category: NotificationCategory.Message,
      ),
    );
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }
}
