import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Initialize Timezone data (required for zonedSchedule)
    tz.initializeTimeZones();

    // 2. Android Initialization Settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    // 3. iOS Initialization Settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4. Combined Settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 5. Initialize the plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );

    // Request Android 13+ Runtime Notification Permissions
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // 6. Schedule our daily alarms
    await _scheduleDailyReminders();
  }

  Future<void> _scheduleDailyReminders() async {
    // Clear any previous duplicate schedules
    await _notificationsPlugin.cancelAll();

    // Setup channel details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'attendance_reminders_channel',
      'Attendance Reminders',
      channelDescription: 'Daily alerts to check-in and check-out on time.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule 9:30 AM Morning Check-In Alarm
    await _scheduleDailyTime(
      id: 101,
      title: '📅 Attendance Check-In Open',
      body: 'Good morning! The check-in window is open (9:30 AM - 9:50 AM). Place your fingerprint to check in on time!',
      hour: 9,
      minute: 30,
      notificationDetails: platformDetails,
    );

    // Schedule 4:30 PM Afternoon Check-Out Alarm
    await _scheduleDailyTime(
      id: 102,
      title: '📅 Attendance Check-Out Open',
      body: 'The check-out window is now open (4:30 PM - 5:00 PM). Don\'t forget to place your fingerprint before leaving!',
      hour: 16,
      minute: 30,
      notificationDetails: platformDetails,
    );
  }

  Future<void> _scheduleDailyTime({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails notificationDetails,
  }) async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If scheduled time has already passed today, schedule it for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily at this exact time!
      );
    } catch (e) {
      // Safely catch platform exceptions on emulators or configurations
      print('Notification Service Error: $e');
    }
  }
}
