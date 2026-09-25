import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diax/db/database_helper.dart';
import 'package:diax/widgets/reminder_list.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Единица измерения: 'mmol' (ммоль/л) или 'mgdl' (мг/дл)
  String _glucoseUnit = 'mmol';

  // ID текущего пользователя (получаем из SharedPreferences)
  int _userId = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUnit = prefs.getString('glucose_unit') ?? 'mmol';
    final savedUserId = prefs.getInt('user_id') ?? 1;

    if (!mounted) return;
    setState(() {
      _glucoseUnit = savedUnit;
      _userId = savedUserId;
    });
  }

  // Изменение единицы измерения
  Future<void> _changeGlucoseUnit(String newUnit) async {
    setState(() {
      _glucoseUnit = newUnit;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('glucose_unit', newUnit);

    // Также сохраняем в таблицу settings
    try {
      final unitInt = newUnit == 'mmol' ? 0 : 1;
      await DatabaseHelper.instance.saveSettings(
        _userId,
        unitInt,
        '14:00',
        '08:00',
      );
    } catch (e) {
      // Игнорируем — таблица settings может быть ещё не заполнена
      debugPrint('Ошибка сохранения настроек в БД: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==================== БЛОК: ЕДИНИЦА ИЗМЕРЕНИЯ ====================
          Card(
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
                  Row(
                    children: const [
                      Icon(Icons.water_drop, color: Colors.redAccent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Единица измерения глюкозы',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'ммоль/л',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _glucoseUnit == 'mmol'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _glucoseUnit == 'mmol'
                              ? Colors.blueAccent
                              : Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _glucoseUnit == 'mmol' ? 0 : 1,
                          min: 0,
                          max: 1,
                          divisions: 1,
                          activeColor: Colors.blueAccent,
                          onChanged: (value) {
                            _changeGlucoseUnit(value == 0 ? 'mmol' : 'mgdl');
                          },
                        ),
                      ),
                      Text(
                        'мг/дл',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _glucoseUnit == 'mgdl'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _glucoseUnit == 'mgdl'
                              ? Colors.blueAccent
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _glucoseUnit == 'mmol'
                        ? 'Сейчас выбрано: ммоль/л'
                        : 'Сейчас выбрано: мг/дл',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==================== ЗАГОЛОВОК: НАПОМИНАНИЯ ====================
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: const [
                Icon(Icons.notifications_active, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Напоминания',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // ==================== НАПОМИНАНИЯ ОБ ИЗМЕРЕНИИ ====================
          ReminderList(
            userId: _userId,
            type: 'measure',
            title: 'Измерение сахара',
            icon: Icons.water_drop,
            color: Colors.redAccent,
            body: 'Пора измерить уровень сахара в крови',
          ),

          const SizedBox(height: 12),

          // ==================== НАПОМИНАНИЯ О ПЕРЕКУСАХ ====================
          ReminderList(
            userId: _userId,
            type: 'snack',
            title: 'Перекусы',
            icon: Icons.apple,
            color: Colors.green,
            body: 'Время перекусить',
          ),

          const SizedBox(height: 12),

          // ==================== НАПОМИНАНИЯ О ПРИЁМАХ ПИЩИ ====================
        ],
      ),
    );
  }
}
