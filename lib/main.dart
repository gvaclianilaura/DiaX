import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:diax/screens/register_screen.dart';

void main() async {
  // Обязательно, если что-то делаем до runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // === ИНИЦИАЛИЗАЦИЯ УВЕДОМЛЕНИЙ ===
  await AwesomeNotifications().initialize(
    // Иконка по умолчанию (null — стандартная)
    null,
    [
      NotificationChannel(
        channelKey: 'reminders_channel',
        channelName: 'Напоминания',
        channelDescription:
            'Напоминания об измерении сахара, приёмах пищи и перекусах',
        importance: NotificationImportance.High,
        defaultColor: Colors.blueAccent,
        ledColor: Colors.white,
        playSound: true,
        enableVibration: true,
      ),
    ],
  );

  // Запрос разрешения (для Android 13+)
  await AwesomeNotifications().requestPermissionToSendNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diax',
      debugShowCheckedModeBanner: false,

      // === РУССКАЯ ЛОКАЛИЗАЦИЯ ===
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      locale: const Locale('ru', 'RU'),

      // === ТЕМА ===
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),

      // === ГЛАВНЫЙ ЭКРАН ===
      // Начинаем с регистрации. После успешного входа пользователь попадёт в MainScreen.
      home: const RegisterScreen(),
    );
  }
}
