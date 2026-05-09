import 'package:flutter/foundation.dart';
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
    if (_initialized || kIsWeb) return;

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

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Request notification permissions (iOS/Android 13+)
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
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
    if (kIsWeb) return;
    // Cancel all existing water reminders first
    await cancelWaterReminders();

    final schedule = profile.waterSchedule;
    final isFemale = profile.gender == 'female';

    for (int i = 0; i < schedule.length; i++) {
      final item   = schedule[i];
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
        title: '💧 وقت الترطيب ($label)',
        body: isFemale 
          ? 'يا هلا، جا وقت ترطبين جسمك وتشربين $amountStr.. جعلها بالعافية على قلبك! 🥤'
          : 'يا هلا، جا وقت ترطب جسمك وتشرب $amountStr.. جعلها بالعافية على قلبك! 🥤',
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
      channelDescription: 'تنبيهات يومية لتحفيزك والحفاظ على صحتك',
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
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Cancel all water reminder notifications
  Future<void> cancelWaterReminders() async {
    if (kIsWeb) return;
    for (int i = 0; i < 20; i++) {
      await _plugin.cancel(id: 100 + i);
    }
  }

  /// Schedule calorie reminders (Breakfast, Lunch, Dinner)
  Future<void> scheduleCalorieReminders(UserProfile? profile) async {
    if (kIsWeb) return;
    await cancelReminders();
    final isFemale = profile?.gender == 'female';

    // Breakfast: 8:30 AM
    await _scheduleDailyNotification(
      id: 200,
      hour: 8,
      minute: 30,
      title: '🍳 فطورك الصحي ينتظرك',
      body: isFemale 
        ? 'صباح الخير والجمال! سجلي فطورك الحين وخلينا نبدأ يومنا بهمة عالية. ☀️'
        : 'صباح الخير والجمال! سجل فطورك الحين وخلنا نبدأ يومنا بهمة عالية. ☀️',
      channelId: 'calorie_reminders',
      channelName: 'تذكير الوجبات',
    );

    // Lunch: 1:30 PM
    await _scheduleDailyNotification(
      id: 201,
      hour: 13,
      minute: 30,
      title: '🥗 جا وقت الغداء',
      body: isFemale 
        ? 'عوافي على قلبك! لا تنسين تسجلين غداك عشان تشوفين وش باقي لك اليوم. 🍱'
        : 'عوافي على قلبك! لا تنسى تسجل غداك عشان تشوف وش باقي لك اليوم. 🍱',
      channelId: 'calorie_reminders',
      channelName: 'تذكير الوجبات',
    );

    // Dinner: 7:30 PM
    await _scheduleDailyNotification(
      id: 202,
      hour: 19,
      minute: 30,
      title: '🍽️ وجبة العشاء',
      body: isFemale 
        ? 'بالعافية مقدماً! سجلي عشاك واختمي يومك بأفضل نتيجة تفتخرين فيها. ✨'
        : 'بالعافية مقدماً! سجل عشاك واختم يومك بأفضل نتيجة تفتخر فيها. ✨',
      channelId: 'calorie_reminders',
      channelName: 'تذكير الوجبات',
    );

    // Weight Tracker: Saturday 10:00 AM (Weekly)
    await _scheduleWeeklyNotification(
      id: 300,
      day: DateTime.saturday,
      hour: 10,
      minute: 0,
      title: '⚖️ وش صار على الميزان؟',
      body: isFemale 
        ? 'صباح السبت الجميل، جا وقت تحديث وزنك عشان نشوف التقدم الرهيب اللي حققتيه! 💪'
        : 'صباح السبت الجميل، جا وقت تحديث وزنك عشان نشوف التقدم الرهيب اللي حققته! 💪',
      channelId: 'weight_reminders',
      channelName: 'تذكير الوزن',
    );
  }

  /// Cancel calorie and weight reminders
  Future<void> cancelReminders() async {
    if (kIsWeb) return;
    await _plugin.cancel(id: 200);
    await _plugin.cancel(id: 201);
    await _plugin.cancel(id: 202);
    await _plugin.cancel(id: 300);
  }

  /// Schedule a weekly repeating notification
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required int day,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String channelId = 'general',
    String channelName = 'تنبيهات عامة',
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Find next specified weekday
    while (scheduled.weekday != day || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      channelId, channelName,
      importance: Importance.high, priority: Priority.high,
      icon: '@mipmap/ic_launcher', playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
    
    await _plugin.zonedSchedule(
      id: id, title: title, body: body,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Send a test notification after 5 seconds to verify background behavior
  Future<void> showImmediateTestNotification({bool isFemale = false}) async {
    if (kIsWeb) return;
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'تنبيهات التجربة',
      channelDescription: 'قناة لاختبار وصول التنبيهات',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id: 999,
      title: '🔔 تجربة التنبيهات',
      body: isFemale 
        ? 'أبشرك، التنبيهات شغالة زي اللوز حتى والتطبيق مقفل!' 
        : 'أبشرك، التنبيهات شغالة زي اللوز حتى والتطبيق مقفل!',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
