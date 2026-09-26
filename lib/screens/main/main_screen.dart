import 'package:flutter/material.dart';

// Импорты экранов, которые будут отображаться во вкладках
import 'package:diax/screens/tabs/calculator_screen.dart';
import 'package:diax/screens/tabs/calendar_screen.dart';
import 'package:diax/screens/tabs/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Индекс текущей выбранной вкладки
  int _selectedIndex = 0;

  // Список экранов, которые будут переключаться через нижнее меню.
  // ПОРЯДОК ВАЖЕН: индекс в этом списке соответствует индексу в BottomNavigationBarItem.
  final List<Widget> _screens = const [
    CalculatorScreen(), // Индекс 0
    CalendarScreen(), // Индекс 1
    SettingsScreen(), // Индекс 2
  ];

  // Метод, вызываемый при нажатии на элемент меню
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack сохраняет состояние каждого экрана при переключении.
      // Это значит, что если пользователь что-то ввел на одном экране,
      // переключился на другой и вернулся — данные не потеряются.
      body: IndexedStack(index: _selectedIndex, children: _screens),

      // Нижнее меню навигации
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Тип "fixed" нужен, чтобы все иконки были подписаны и не "прыгали"
        type: BottomNavigationBarType.fixed,
        // Цвета (можно вынести в тему приложения)
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Калькулятор',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Календарь',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
