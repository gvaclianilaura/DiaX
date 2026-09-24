import 'package:flutter/material.dart';
import 'screens/register_screen.dart';
import 'services/notification_service.dart'; // 1. Добавили импорт

void main() async { // 2. Добавили слово async
  // 3. Обязательная строка для работы с системой до запуска runApp
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // 4. Запускаем наш сервис уведомлений
  await NotificationService.instance.init(); 

  runApp(const DiaxApp());
}

class DiaxApp extends StatelessWidget {
  const DiaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const RegisterScreen(),
    );
  }
}