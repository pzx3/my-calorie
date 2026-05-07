import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/user_profile.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification plugin
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Request notification permissions (iOS/Android 13+)
  Future<bool> requestPermission() async {
    // Android
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    // iOS
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true, badge: true, sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Schedule water reminders based on profile settings
  Future<void> scheduleWaterReminders(UserProfile profile, {bool isOz = false}) async {
    // Cancel all existing water reminders first
    await cancelWaterReminders();

    final schedule = profile.waterSchedule;

    for (int i = 0; i < schedule.length; i++) {
      final item   = schedule[i];
      final time   = item['time'] as String;
      final label  = item['label'] as String;
      final ml     = item['ml'] as int;
      final hour   = item['hour'] as int;
      final minute = item['minute'] as int;

      String amountStr;
      if (isOz) {
        final oz = (ml / 29.5735).round();
        amountStr = '$oz oz';
      } else {
        amountStr = '$ml مل';
      }

      await _scheduleDailyNotification(
        id: 100 + i, // IDs 100-119 for water
        hour: hour,
        minute: minute,
        title: '💧 $label',
        body: 'حان وقت ترطيب جسمك! اشرب $amountStr ($time)',
      );
    }
  }

  /// Schedule a daily repeating notification at specific time
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String channelId = 'water_reminders',
    String channelName = 'تذكير الماء',
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If the time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'تنبيهات منتظمة من التطبيق',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Cancel all water reminder notifications
  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < 20; i++) {
      await _plugin.cancel(100 + i);
    }
  }

  /// Schedule calorie reminders (Breakfast, Lunch, Dinner)
  Future<void> scheduleCalorieReminders() async {
    await cancelCalorieReminders();

    // Breakfast: 8:30 AM
    await _scheduleDailyNotification(
      id: 200,
      hour: 8,
      minute: 30,
      title: '🍳 تذكير الفطور',
      body: 'صباح الخير! لا تنسَ تسجيل وجبة فطورك لتبقى ملتزماً بهدفك.',
      channelId: 'calorie_reminders',
      channelName: 'تذكير الوجبات',
    );

    // Lunch: 1:30 PM
    await _scheduleDailyNotification(
      id: 201,
      hour: 13,
      minute: 30,
      title: '🥗 تذكير الغداء',
      body: 'حان وقت الغداء! سجل وجبتك الآن لتعرف ما تبقى لك من سعرات.',
      channelId: 'calorie_reminders',
      channelName: 'تذكير الوجبات',
    );

    // Dinner: 7:30 PM
    await _scheduleDailyNotification(
      id: 202,
      hour: 19,
      minute: 30,
      title: '🍽️ تذكير العشاء',
      body: 'هل انتهيت من العشاء؟ لا تنسَ تسجيل وجبتك الأخيرة لهذا اليوم.',
      channelId: 'calorie_reminders',
      channelName: 'تذكير الوجبات',
    );
  }

  /// Cancel calorie reminders
  Future<void> cancelCalorieReminders() async {
    await _plugin.cancel(200);
    await _plugin.cancel(201);
    await _plugin.cancel(202);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
