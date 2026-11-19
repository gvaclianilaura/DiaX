import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:diax/models/calendar_event.dart';
import 'package:diax/services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  String? _selectedMeal;
  String _glucoseUnit = 'mmol'; // По умолчанию
  int? _userId; // ID текущего пользователя из SharedPreferences

  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _breadUnitsController = TextEditingController();
  final TextEditingController _insulinController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  Set<String> _filledKeys = {};

  @override
  void initState() {
    super.initState();
    _loadSettingsAndData(); // Грузим настройки и события с сервера при старте
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    _breadUnitsController.dispose();
    _insulinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // === Загрузка настроек, ID пользователя и событий с сервера ===
  Future<void> _loadSettingsAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUnit = prefs.getString('glucose_unit') ?? 'mmol';
    
    // Получаем ID залогиненного пользователя (сохраняется при логине/регистрации)
    // Если у тебя ID хранится под другим ключом, поправь здесь:
    final userId = prefs.getInt('user_id') ?? 1; 

    setState(() {
      _glucoseUnit = savedUnit;
      _userId = userId;
    });

    // Получаем события календаря с бэкенда FastAPI
    final events = await ApiService.getCalendarEvents(userId);

    // Фильтруем события, которые привязаны именно к выбранной дате
    final selectedDateStr = _dateKey(_selectedDay);
    final filled = <String>{};

    for (var event in events) {
      // Сравниваем даты начала события с выбранным днем
      final eventDateStr = _dateKey(event.startTime);
      if (eventDateStr == selectedDateStr) {
        filled.add(event.title);
      }
    }

    if (!mounted) return;
    setState(() {
      _filledKeys = filled;
    });
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Календарь'),
        backgroundColor: Colors.green, // Зеленая шапка
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ============================================================
          // ВЕРХНЯЯ ЧАСТЬ: КАЛЕНДАРЬ
          // ============================================================
          Container(
            height: screenHeight * 0.42,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.green.shade100, width: 1),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TableCalendar(
                  locale: 'ru_RU',
                  rowHeight: (constraints.maxHeight - 90) / 6,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // Зеленый месяц
                    ),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
                    weekendStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange, // Смягчили красный на оранжевый для выходных
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    cellMargin: const EdgeInsets.all(4),
                    cellPadding: EdgeInsets.zero,
                    todayDecoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.3), // Бледно-зеленый сегодня
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.green, // Насыщенно-зеленый выбранный день
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(color: Colors.orange),
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
                    _loadSettingsAndData(); // Обновляем данные при клике на день
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
                      color: Colors.teal, // Бирюзовый
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

  Future<void> _openMealForm(String mealName) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUnit = prefs.getString('glucose_unit') ?? 'mmol';
    final userId = _userId ?? 1;

    // Ищем существующее событие с бэкенда для этого приема пищи на этот день
    final events = await ApiService.getCalendarEvents(userId);
    final selectedDateStr = _dateKey(_selectedDay);

    CalendarEvent? existing;
    for (var event in events) {
      if (_dateKey(event.startTime) == selectedDateStr && event.title == mealName) {
        existing = event;
        break;
      }
    }

    // Парсим описание, если оно сохранялось в формате "Глюкоза: X | ХЕ: Y | Инсулин: Z | Заметка"
    String glucoseVal = '';
    String breadVal = '';
    String insulinVal = '';
    String noteVal = '';

    if (existing?.description != null && existing!.description!.isNotEmpty) {
      final parts = existing.description!.split(' | ');
      for (var part in parts) {
        if (part.startsWith('Глюкоза:')) {
          glucoseVal = part.replaceFirst('Глюкоза:', '').trim();
        } else if (part.startsWith('ХЕ:')) {
          breadVal = part.replaceFirst('ХЕ:', '').trim();
        } else if (part.startsWith('Инсулин:')) {
          insulinVal = part.replaceFirst('Инсулин:', '').trim();
        } else if (part.startsWith('Заметка:')) {
          noteVal = part.replaceFirst('Заметка:', '').trim();
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _glucoseUnit = savedUnit;
      _selectedMeal = mealName;
      _glucoseController.text = glucoseVal;
      _breadUnitsController.text = breadVal;
      _insulinController.text = insulinVal;
      _noteController.text = noteVal;
    });
  }

  void _closeMealForm() {
    setState(() {
      _selectedMeal = null;
    });
  }

  // === Сохранение данных на бэкенд FastAPI через ApiService ===
  Future<void> _saveMealEntry() async {
    final mealName = _selectedMeal;
    if (mealName == null) return;

    final userId = _userId ?? 1;
    final glucose = _glucoseController.text.trim();
    final breadUnits = _breadUnitsController.text.trim();
    final insulin = _insulinController.text.trim();
    final note = _noteController.text.trim();

    // Собираем описание в читаемый вид для бэкенда
    final description = 'Глюкоза: $glucose | ХЕ: $breadUnits | Инсулин: $insulin | Заметка: $note';

    // Формируем точное время начала и окончания события на выбранный день
    final startTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      12, 0, 0, // Можно зафиксировать время или сделать текущее
    );
    final endTime = startTime.add(const Duration(hours: 1));

    final event = CalendarEvent(
      userId: userId,
      title: mealName,
      description: description,
      startTime: startTime,
      endTime: endTime,
    );

    // Отправляем на сервер
    bool success = await ApiService.createCalendarEvent(event);

    if (!mounted) return;

    if (success) {
      await _loadSettingsAndData(); // Обновляем галочки на экране

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Сохранено в облако: $mealName\n'
            'Глюкоза: $glucose ${_glucoseUnit == 'mmol' ? 'ммоль/л' : 'мг/дл'}\n'
            'ХЕ: $breadUnits\n'
            'Инсулин: $insulin ед\n'
            'Заметка: $note',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка сохранения на сервер!'),
          backgroundColor: Colors.red,
        ),
      );
    }

    _closeMealForm();
  }

  Widget _buildMealForm() {
    final unitLabel = _glucoseUnit == 'mmol' ? 'ммоль/л' : 'мг/дл';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50, // Нежно-зеленый фон формы
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedMeal ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: unitLabel,
                isDense: true,
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(
                hintText: '0.0',
                suffixText: 'ХЕ',
                isDense: true,
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Строка 3: Инсулин
          _buildFormRow(
            icon: Icons.vaccines,
            iconColor: Colors.blueAccent,
            label: 'Инсулин',
            field: TextField(
              controller: _insulinController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: 'ед',
                isDense: true,
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Строка 4: Заметки
          _buildFormRow(
            icon: Icons.edit_note,
            iconColor: Colors.grey.shade600,
            label: 'Заметки',
            field: TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Дополнительные сведения...',
                isDense: true,
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
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
                backgroundColor: Colors.green, // Зеленая кнопка
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