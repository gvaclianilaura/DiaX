import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:diax/db/database_helper.dart';
import 'package:diax/models/meal_entry.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  String? _selectedMeal;
  String _glucoseUnit = 'mmol';

  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _breadUnitsController = TextEditingController();
  final TextEditingController _insulinController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  Set<String> _filledKeys = {};

  @override
  void dispose() {
    _glucoseController.dispose();
    _breadUnitsController.dispose();
    _insulinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadFilledKeys() async {
    final entries = await DatabaseHelper.instance.getMealEntriesForDate(
      _dateKey(_selectedDay),
    );
    if (!mounted) return;
    setState(() {
      _filledKeys = entries.map((e) => e.mealName).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь'), centerTitle: true),
      body: Column(
        children: [
          // ============================================================
          // ВЕРХНЯЯ ЧАСТЬ: КАЛЕНДАРЬ
          // ============================================================
          Container(
            height: screenHeight * 0.42,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TableCalendar(
                  locale: 'ru_RU',
                  // === Фиксированная высота строки календаря ===
                  // (высота контейнера − высота шапки) / 6 строк
                  rowHeight: (constraints.maxHeight - 90) / 6,

                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
                    weekendStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    cellMargin: const EdgeInsets.all(4),
                    cellPadding: EdgeInsets.zero,
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(color: Colors.redAccent),
                    outsideDaysVisible: false,
                    defaultTextStyle: const TextStyle(fontSize: 14),
                  ),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  focusedDay: _focusedDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _loadFilledKeys();
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                );
              },
            ),
          ),

          // ============================================================
          // НИЖНЯЯ ЧАСТЬ: КНОПКИ / ФОРМА
          // ============================================================
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedMeal == null) ...[
                    _MainMealButton(
                      label: 'Завтрак',
                      icon: Icons.breakfast_dining,
                      color: Colors.orange,
                      isFilled: _filledKeys.contains('Завтрак'),
                      onTap: () => _openMealForm('Завтрак'),
                    ),
                    const SizedBox(height: 4),
                    _SnackButton(
                      label: 'Перекус',
                      icon: Icons.apple,
                      isFilled: _filledKeys.contains('Перекус после завтрака'),
                      onTap: () => _openMealForm('Перекус после завтрака'),
                    ),
                    const SizedBox(height: 8),
                    _MainMealButton(
                      label: 'Обед',
                      icon: Icons.lunch_dining,
                      color: Colors.green,
                      isFilled: _filledKeys.contains('Обед'),
                      onTap: () => _openMealForm('Обед'),
                    ),
                    const SizedBox(height: 4),
                    _SnackButton(
                      label: 'Перекус',
                      icon: Icons.cookie,
                      isFilled: _filledKeys.contains('Перекус после обеда'),
                      onTap: () => _openMealForm('Перекус после обеда'),
                    ),
                    const SizedBox(height: 8),
                    _MainMealButton(
                      label: 'Ужин',
                      icon: Icons.dinner_dining,
                      color: Colors.deepPurple,
                      isFilled: _filledKeys.contains('Ужин'),
                      onTap: () => _openMealForm('Ужин'),
                    ),
                    const SizedBox(height: 4),
                    _SnackButton(
                      label: 'Перекус',
                      icon: Icons.local_cafe,
                      isFilled: _filledKeys.contains('Перекус после ужина'),
                      onTap: () => _openMealForm('Перекус после ужина'),
                    ),
                  ] else ...[
                    _buildMealForm(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ОТКРЫТИЕ ФОРМЫ И ЗАГРУЗКА СУЩЕСТВУЮЩЕЙ ЗАПИСИ
  // ============================================================
  Future<void> _openMealForm(String mealName) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUnit = prefs.getString('glucose_unit') ?? 'mmol';

    final existing = await DatabaseHelper.instance.getMealEntry(
      _dateKey(_selectedDay),
      mealName,
    );

    if (!mounted) return;

    setState(() {
      _glucoseUnit = savedUnit;
      _selectedMeal = mealName;

      _glucoseController.text = existing?.glucose?.toString() ?? '';
      _breadUnitsController.text = existing?.breadUnits?.toString() ?? '';
      _insulinController.text = existing?.insulin?.toString() ?? '';
      _noteController.text = existing?.note ?? '';
    });
  }

  void _closeMealForm() {
    setState(() {
      _selectedMeal = null;
    });
  }

  // ============================================================
  // СОХРАНЕНИЕ В БД
  // ============================================================
  Future<void> _saveMealEntry() async {
    final mealName = _selectedMeal;
    if (mealName == null) return;

    final glucose = _parseDouble(_glucoseController.text);
    final breadUnits = _parseDouble(_breadUnitsController.text);
    final insulin = _parseDouble(_insulinController.text);
    final note = _noteController.text.trim();

    final entry = MealEntry(
      date: _dateKey(_selectedDay),
      mealName: mealName,
      glucose: glucose,
      breadUnits: breadUnits,
      insulin: insulin,
      note: note,
    );

    if (entry.isEmpty) {
      await DatabaseHelper.instance.deleteMealEntry(entry.date, entry.mealName);
    } else {
      await DatabaseHelper.instance.saveMealEntry(entry);
    }

    await _loadFilledKeys();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          entry.isEmpty
              ? 'Запись удалена'
              : 'Сохранено: $mealName\n'
                    'Глюкоза: ${_glucoseController.text} '
                    '${_glucoseUnit == 'mmol' ? 'ммоль/л' : 'мг/дл'}\n'
                    'ХЕ: ${_breadUnitsController.text}\n'
                    'Инсулин: ${_insulinController.text} ед\n'
                    'Заметка: $note',
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    _closeMealForm();
  }

  double? _parseDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  // ============================================================
  // ФОРМА ВВОДА
  // ============================================================
  Widget _buildMealForm() {
    final unitLabel = _glucoseUnit == 'mmol' ? 'ммоль/л' : 'мг/дл';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedMeal ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _closeMealForm,
                tooltip: 'Закрыть',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Строка 1: Глюкоза
          _buildFormRow(
            icon: Icons.water_drop,
            iconColor: Colors.redAccent,
            label: 'Глюкоза',
            field: TextField(
              controller: _glucoseController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: unitLabel,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Строка 2: Хлебные единицы
          _buildFormRow(
            icon: Icons.bakery_dining,
            iconColor: Colors.brown,
            label: 'Хлебные ед.',
            field: TextField(
              controller: _breadUnitsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                hintText: '0.0',
                suffixText: 'ХЕ',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Строка 3: Инсулин
          _buildFormRow(
            icon: Icons.vaccines,
            iconColor: Colors.blue,
            label: 'Инсулин',
            field: TextField(
              controller: _insulinController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: 'ед',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Строка 4: Заметки
          _buildFormRow(
            icon: Icons.edit_note,
            iconColor: Colors.blueGrey,
            label: 'Заметки',
            field: TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Дополнительные сведения...',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saveMealEntry,
              icon: const Icon(Icons.check),
              label: const Text(
                'Сохранить',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget field,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: field),
      ],
    );
  }
}

// ============================================================
// ВИДЖЕТ: Основная кнопка приёма пищи
// ============================================================
class _MainMealButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isFilled;
  final VoidCallback onTap;

  const _MainMealButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isFilled) Icon(Icons.check_circle, size: 18, color: color),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.2),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}

// ============================================================
// ВИДЖЕТ: Кнопка перекуса
// ============================================================
class _SnackButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isFilled;
  final VoidCallback onTap;

  const _SnackButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        height: 42,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 14)),
              ),
              if (isFilled)
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
            ],
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: BorderSide(color: Colors.grey.shade400, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      ),
    );
  }
}
