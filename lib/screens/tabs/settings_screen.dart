import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Единица измерения: 'mmol' (ммоль/л) или 'mgdl' (мг/дл)
  String _glucoseUnit = 'mmol';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Загрузка настроек из shared_preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _glucoseUnit = prefs.getString('glucose_unit') ?? 'mmol';
    });
  }

  // Изменение единицы измерения
  Future<void> _changeGlucoseUnit(String newUnit) async {
    setState(() {
      _glucoseUnit = newUnit;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('glucose_unit', newUnit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === БЛОК: ЕДИНИЦА ИЗМЕРЕНИЯ ГЛЮКОЗЫ ===
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

                  // === ПОЛЗУНОК ===
                  Row(
                    children: [
                      // Левая подпись — ммоль/л
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
                            final newUnit = value == 0 ? 'mmol' : 'mgdl';
                            _changeGlucoseUnit(newUnit);
                          },
                        ),
                      ),
                      // Правая подпись — мг/дл
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

                  const SizedBox(height: 8),

                  // Пояснение под ползунком
                  Text(
                    _glucoseUnit == 'mmol'
                        ? 'Сейчас выбрано: миллимоль на литр (ммоль/л)'
                        : 'Сейчас выбрано: миллиграмм на децилитр (мг/дл)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // === МЕСТО ДЛЯ ДРУГИХ НАСТРОЕК ===
          // Сюда позже можно добавить другие пункты настроек
        ],
      ),
    );
  }
}
