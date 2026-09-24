import '../services/notification_service.dart';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _unit = 0; // 0 — ммоль/л, 1 — мг/дл
  TimeOfDay _snackTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _measureTime = const TimeOfDay(hour: 8, minute: 0);

  Future<void> _pickTime(BuildContext context, bool isSnack) async {
    final initialTime = isSnack ? _snackTime : _measureTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isSnack) {
          _snackTime = picked;
        } else {
          _measureTime = picked;
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final snackStr = '${_snackTime.hour.toString().padLeft(2, '0')}:${_snackTime.minute.toString().padLeft(2, '0')}';
    final measureStr = '${_measureTime.hour.toString().padLeft(2, '0')}:${_measureTime.minute.toString().padLeft(2, '0')}';

    await DatabaseHelper.instance.saveSettings(1, _unit, snackStr, measureStr);

    // --- ДОБАВЛЯЕМ УВЕДОМЛЕНИЯ СЮДА ---
    // ID 1 — для перекуса
    await NotificationService.instance.scheduleDailyNotification(
      id: 1,
      title: 'Время перекуса',
      body: 'Пора перекусить, чтобы поддержать уровень сахара!',
      time: _snackTime,
    );

    // ID 2 — для измерения сахара
    await NotificationService.instance.scheduleDailyNotification(
      id: 2,
      title: 'Измерение сахара',
      body: 'Пришло время измерить уровень глюкозы.',
      time: _measureTime,
    );
    // ----------------------------------

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки успешно сохранены!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Единицы измерения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('ммоль/л')),
                  ButtonSegment(value: 1, label: Text('мг/дл')),
                ],
                selected: {_unit},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() => _unit = newSelection.first);
                },
              ),
            ),
            const Divider(height: 48),
            
            const Text('Уведомления', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Время перекуса'),
              trailing: Text(_snackTime.format(context), style: const TextStyle(fontSize: 18, color: Colors.indigo)),
              onTap: () => _pickTime(context, true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Измерение сахара'),
              trailing: Text(_measureTime.format(context), style: const TextStyle(fontSize: 18, color: Colors.indigo)),
              onTap: () => _pickTime(context, false),
            ),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}