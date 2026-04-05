import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Notification IDs
// 1001 : sleep reminder
// 1002 : feed reminder
// 2001–2024 : monthly milestone (month 1–24)

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Channels ───────────────────────────────────────────────────────────────

  static const _channelReminder = AndroidNotificationChannel(
    'sara_reminders',
    'Baby Reminders',
    description: 'Gentle reminders to log baby activities',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  static const _channelMilestone = AndroidNotificationChannel(
    'sara_milestones',
    'Milestone Notifications',
    description: 'Monthly milestone updates for your baby',
    importance: Importance.high,
    playSound: true,
  );

  // ─── Init ────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create Android channels
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channelReminder);
    await androidImpl?.createNotificationChannel(_channelMilestone);

    _initialized = true;
  }

  // ─── Permission ──────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    return true;
  }

  Future<bool> get hasPermission async {
    if (Platform.isIOS) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final pending = await impl?.checkPermissions();
      return pending?.isEnabled ?? false;
    }
    if (Platform.isAndroid) {
      return (await Permission.notification.status).isGranted;
    }
    return true;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  bool _isQuietHour() {
    final now = DateTime.now();
    final hour = now.hour;
    // Quiet 22:00 – 07:00
    return hour >= 22 || hour < 7;
  }

  NotificationDetails _reminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'sara_reminders',
        'Baby Reminders',
        channelDescription: 'Gentle reminders to log baby activities',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  NotificationDetails _milestoneDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'sara_milestones',
        'Milestone Notifications',
        channelDescription: 'Monthly milestone updates for your baby',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ─── Sleep Reminder ──────────────────────────────────────────────────────────

  /// Call this when a sleep session ends. Schedules a reminder after [afterMinutes].
  Future<void> scheduleSleepReminder({
    required String babyName,
    required String title,
    required String body,
    int afterMinutes = 90,
  }) async {
    if (_isQuietHour()) return;
    if (!(await hasPermission)) return;

    final scheduledTime = tz.TZDateTime.now(tz.local).add(
      Duration(minutes: afterMinutes),
    );

    await _plugin.zonedSchedule(
      1001,
      title,
      body,
      scheduledTime,
      _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'sleep',
    );

    if (kDebugMode) {
      debugPrint(
        '[NotificationService] Sleep reminder scheduled in $afterMinutes min',
      );
    }
  }

  Future<void> cancelSleepReminder() async {
    await _plugin.cancel(1001);
  }

  // ─── Feed Reminder ───────────────────────────────────────────────────────────

  /// Call this after a feed is logged. Schedules a reminder after [afterMinutes].
  Future<void> scheduleFeedReminder({
    required String title,
    required String body,
    int afterMinutes = 150,
  }) async {
    if (_isQuietHour()) return;
    if (!(await hasPermission)) return;

    final scheduledTime = tz.TZDateTime.now(tz.local).add(
      Duration(minutes: afterMinutes),
    );

    await _plugin.zonedSchedule(
      1002,
      title,
      body,
      scheduledTime,
      _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'feed',
    );

    if (kDebugMode) {
      debugPrint(
        '[NotificationService] Feed reminder scheduled in $afterMinutes min',
      );
    }
  }

  Future<void> cancelFeedReminder() async {
    await _plugin.cancel(1002);
  }

  // ─── Milestone Notifications ─────────────────────────────────────────────────

  /// Schedule monthly milestone notifications for months 1–24 based on birth date.
  Future<void> scheduleMilestoneNotifications({
    required DateTime birthDate,
    required String Function(int month) titleBuilder,
    required String Function(int month) bodyBuilder,
  }) async {
    if (!(await hasPermission)) return;

    // Cancel any previously scheduled milestones before re-scheduling
    for (int i = 1; i <= 24; i++) {
      await _plugin.cancel(2000 + i);
    }

    final now = DateTime.now();

    for (int month = 1; month <= 24; month++) {
      final milestoneDate = DateTime(
        birthDate.year,
        birthDate.month + month,
        birthDate.day,
        9, // 09:00 morning
        0,
      );

      // Skip milestones already in the past
      if (milestoneDate.isBefore(now)) continue;

      final tzScheduled = tz.TZDateTime.from(milestoneDate, tz.local);

      await _plugin.zonedSchedule(
        2000 + month,
        titleBuilder(month),
        bodyBuilder(month),
        tzScheduled,
        _milestoneDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'milestone_$month',
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }

    if (kDebugMode) {
      debugPrint('[NotificationService] Milestone notifications scheduled');
    }
  }

  Future<void> cancelAllMilestoneNotifications() async {
    for (int i = 1; i <= 24; i++) {
      await _plugin.cancel(2000 + i);
    }
  }

  // ─── Settings (SharedPreferences) ────────────────────────────────────────────

  static const _keySleepReminders = 'notif_sleep_reminders';
  static const _keyFeedReminders = 'notif_feed_reminders';
  static const _keyMilestoneNotifs = 'notif_milestones';

  Future<NotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      sleepRemindersEnabled: prefs.getBool(_keySleepReminders) ?? true,
      feedRemindersEnabled: prefs.getBool(_keyFeedReminders) ?? true,
      milestoneNotificationsEnabled:
          prefs.getBool(_keyMilestoneNotifs) ?? true,
    );
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        _keySleepReminders, settings.sleepRemindersEnabled);
    await prefs.setBool(
        _keyFeedReminders, settings.feedRemindersEnabled);
    await prefs.setBool(
        _keyMilestoneNotifs, settings.milestoneNotificationsEnabled);
  }

  // ─── Cancel All ──────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

// ─── Settings Model ───────────────────────────────────────────────────────────

class NotificationSettings {
  final bool sleepRemindersEnabled;
  final bool feedRemindersEnabled;
  final bool milestoneNotificationsEnabled;

  const NotificationSettings({
    this.sleepRemindersEnabled = true,
    this.feedRemindersEnabled = true,
    this.milestoneNotificationsEnabled = true,
  });

  NotificationSettings copyWith({
    bool? sleepRemindersEnabled,
    bool? feedRemindersEnabled,
    bool? milestoneNotificationsEnabled,
  }) {
    return NotificationSettings(
      sleepRemindersEnabled:
          sleepRemindersEnabled ?? this.sleepRemindersEnabled,
      feedRemindersEnabled:
          feedRemindersEnabled ?? this.feedRemindersEnabled,
      milestoneNotificationsEnabled:
          milestoneNotificationsEnabled ?? this.milestoneNotificationsEnabled,
    );
  }
}
