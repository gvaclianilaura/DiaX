import 'package:flutter/material.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart'; 

void main() async {
  // Обязательная строка для работы с системой до запуска runApp
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Запускаем наш сервис уведомлений
  await NotificationService.instance.init(); 

  // ПРОВЕРКА ПАМЯТИ: узнаем, регистрировался ли человек ранее
  bool isLogged = await AuthService.isLoggedIn();

  // Запускаем приложение и передаем ему результат проверки
  runApp(DiaxApp(isLogged: isLogged));
}

class DiaxApp extends StatelessWidget {
  final bool isLogged; // Создаем переменную для хранения статуса

  // Требуем передать статус при запуске DiaxApp
  const DiaxApp({super.key, required this.isLogged});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // УМНЫЙ ЗАПУСК: 
      // Если isLogged == true, показываем MainScreen()
      // Если isLogged == false, показываем RegisterScreen()
      home: isLogged ? const SettingsScreen() : const RegisterScreen(),
    );
  }
}