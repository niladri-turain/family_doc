import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_planner.dart';

/// Payload of expiry reminders; tapping one opens the chat.
const reminderPayload = 'expiry';

/// Shows expiry reminders as phone notifications (scheduled on the phone,
/// no server). Tests replace it through `setupLocator`.
class ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialising;
  bool _askedPermission = false;

  /// Called with [reminderPayload] when a reminder is tapped.
  void Function(String? payload)? onTap;

  /// Safe to call many times; every caller waits for the same start-up
  /// (asking for the launch notification before it finishes gets nothing).
  Future<void> init() => _initialising ??= _initialise();

  Future<void> _initialise() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            // Asked when the first expiry date is saved, not at launch.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => onTap?.call(r.payload),
      );
    } catch (e) {
      debugPrint('Reminders unavailable: $e');
    }
  }

  /// The reminder that opened the app, if any.
  Future<String?> launchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      return details?.didNotificationLaunchApp ?? false
          ? details!.notificationResponse?.payload
          : null;
    } catch (_) {
      return null;
    }
  }

  /// Replaces every pending reminder with [reminders].
  Future<void> schedule(List<PlannedReminder> reminders) async {
    await init();
    try {
      await _plugin.cancelAllPendingNotifications();
      if (reminders.isEmpty) return;
      await _askPermission();
      var id = 0;
      for (final r in reminders) {
        await _plugin.zonedSchedule(
          id: id++,
          // r.at is phone-local time; as an instant it is the same in UTC.
          scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
          title: r.title,
          body: r.body,
          payload: reminderPayload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry_reminders',
              'Expiry reminders',
              channelDescription:
                  'Before a saved document (RC, licence, passport…) expires',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Could not schedule reminders: $e');
    }
  }

  Future<void> _askPermission() async {
    if (_askedPermission) return;
    _askedPermission = true;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
