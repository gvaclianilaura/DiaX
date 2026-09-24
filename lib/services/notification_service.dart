import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart'; // Подключили новую библиотеку
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Инициализируем базу времени
    tz.initializeTimeZones();
    
    // 2. Узнаем текущий часовой пояс телефона и применяем его
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    // 3. Возвращаем правильную иконку (обязательно с @mipmap)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings: initSettings);

    // Запрашиваем права
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);

    // Если время сегодня прошло, ставим на завтра
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'diax_reminders',
      'Напоминания',
      channelDescription: 'Уведомления о перекусах и измерениях',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Наш мгновенный тест
  Future<void> showInstantNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'diax_instant',
      'Тестовые уведомления',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _notificationsPlugin.show(
      999,
      'Проверка связи!',
      'Если ты это видишь, значит всё работает.',
      const NotificationDetails(android: androidDetails),
    );
  }
}