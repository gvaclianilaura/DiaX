import 'package:flutter/material.dart';

import 'package:diax/db/database_helper.dart';
import 'package:diax/services/reminder_scheduler.dart';

class ReminderList extends StatefulWidget {
  final int userId;
  final String type; // 'measure', 'snack', 'meal'
  final String title; // 'Измерение сахара'
  final IconData icon;
  final Color color;
  final String body; // Текст уведомления

  const ReminderList({
    super.key,
    required this.userId,
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    required this.body,
  });

  @override
  State<ReminderList> createState() => _ReminderListState();
}

class _ReminderListState extends State<ReminderList> {
  List<Map<String, dynamic>> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DatabaseHelper.instance.getReminders(
      widget.userId,
      widget.type,
    );
    if (!mounted) return;
    setState(() {
      _reminders = list;
      _loading = false;
    });
  }

  // === Добавление времени ===
  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Выберите время напоминания',
      cancelText: 'Отмена',
      confirmText: 'OK',
    );
    if (picked == null) return;

    final timeString =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';

    // Сохраняем в БД, получаем ID
    final newId = await DatabaseHelper.instance.addReminder(
      widget.userId,
      widget.type,
      timeString,
    );

    // Планируем ежедневное уведомление
    await ReminderScheduler.scheduleDaily(
      id: newId,
      time: timeString,
      title: widget.title,
      body: widget.body,
    );

    await _load();
  }

  // === Редактирование времени ===
  Future<void> _editTime(Map<String, dynamic> reminder) async {
    final parts = (reminder['time'] as String).split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Изменить время',
      cancelText: 'Отмена',
      confirmText: 'OK',
    );
    if (picked == null) return;

    final timeString =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';

    final id = reminder['id'] as int;

    // Обновляем в БД
    await DatabaseHelper.instance.updateReminder(id, timeString);

    // Пересоздаём уведомление с новым временем
    await ReminderScheduler.cancel(id);
    await ReminderScheduler.scheduleDaily(
      id: id,
      time: timeString,
      title: widget.title,
      body: widget.body,
    );

    await _load();
  }

  // === Удаление ===
  Future<void> _delete(Map<String, dynamic> reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить напоминание?'),
        content: Text('Время ${reminder['time']} будет удалено.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final id = reminder['id'] as int;

    // Отменяем уведомление
    await ReminderScheduler.cancel(id);

    // Удаляем из БД
    await DatabaseHelper.instance.deleteReminder(id);

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_reminders.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_reminders.length}',
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Список времён
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_reminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Напоминаний нет. Нажмите «+ Добавить время».',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              )
            else
              ..._reminders.map((r) => _buildTimeTile(r)).toList(),

            const SizedBox(height: 8),

            // Кнопка «Добавить время»
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Добавить время'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.color,
                  side: BorderSide(color: widget.color.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(Map<String, dynamic> reminder) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reminder['time'] as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            color: Colors.blueGrey,
            onPressed: () => _editTime(reminder),
            tooltip: 'Изменить',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.redAccent,
            onPressed: () => _delete(reminder),
            tooltip: 'Удалить',
          ),
        ],
      ),
    );
  }
}
