import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      null, // Автоматически подхватит иконку приложения
      [
        NotificationChannel(
          channelKey: 'diax_alerts',
          channelName: 'Напоминания DiaX',
          channelDescription: 'Уведомления о перекусах и измерениях',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          criticalAlerts: true, // Помогает пробить беззвучный режим
        )
      ],
    );

    // Запрашиваем права максимально надежным способом
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    var scheduleTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduleTime.isBefore(now)) {
      scheduleTime = scheduleTime.add(const Duration(days: 1));
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'diax_alerts',
        title: title,
        body: body,
        wakeUpScreen: true, // Принудительно включит экран телефона
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduleTime,
        allowWhileIdle: true, // Игнорировать энергосбережение
        preciseAlarm: true,   // Игнорировать оптимизацию времени
      ),
    );
  }

  Future<void> showInstantNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: 'diax_alerts',
        title: 'Проверка связи!',
        body: 'Awesome Notifications успешно пробил защиту!',
        wakeUpScreen: true,
      ),
    );
  }
}