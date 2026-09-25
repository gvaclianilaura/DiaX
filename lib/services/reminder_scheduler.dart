import 'package:awesome_notifications/awesome_notifications.dart';

class ReminderScheduler {
  /// Запланировать ежедневное напоминание в HH:mm
  static Future<void> scheduleDaily({
    required int id,
    required String time, // 'HH:mm'
    required String title,
    required String body,
  }) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminders_channel',
        title: title,
        body: body,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true, // повторять каждый день
      ),
    );
  }

  static Future<void> cancel(int id) async {
    await AwesomeNotifications().cancel(id);
  }
}
