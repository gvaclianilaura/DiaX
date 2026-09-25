import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

// Импорты экранов
// ⚠️ Проверьте пути под свою структуру папок!
import 'package:diax/screens/register_screen.dart';
// Если register_screen лежит просто в lib/screens/, используйте:
// import 'package:diax/screens/register_screen.dart';

void main() async {
  // Обязательная инициализация перед использованием плагинов
  WidgetsFlutterBinding.ensureInitialized();

  // === ИНИЦИАЛИЗАЦИЯ УВЕДОМЛЕНИЙ ===
  await AwesomeNotifications().initialize(
    // Иконка приложения для уведомлений (можно оставить null)
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Основные уведомления',
        channelDescription: 'Канал для основных уведомлений приложения',
        defaultColor: const Color(0xFF2196F3),
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
      NotificationChannel(
        channelKey: 'scheduled_channel',
        channelName: 'Запланированные уведомления',
        channelDescription: 'Канал для напоминаний по расписанию',
        defaultColor: const Color(0xFFFF9800),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        // Разрешить точные уведомления (важно для Android 12+)
        defaultPrivacy: NotificationPrivacy.Private,
      ),
    ],
    // Отладочные логи (можно выключить в релизе)
    debug: true,
  );

  // Запрос разрешения на отправку уведомлений
  // (на Android 13+ и iOS это обязательно, иначе уведомления не придут)
  await AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  runApp(const DiaxApp());
}

class DiaxApp extends StatelessWidget {
  const DiaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diax',
      debugShowCheckedModeBanner: false, // Убираем красную ленточку "DEBUG"
      // === НАСТРОЙКА ТЕМЫ (можно менять по вкусу) ===
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),

      // === ЛОКАЛИЗАЦИЯ (русский язык для календаря и системных виджетов) ===
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      locale: const Locale('ru', 'RU'), // Принудительно русский
      // === ТОЧКА ВХОДА ===
      // Стартовый экран — регистрация/вход
      home: const RegisterScreen(),

      // Маршруты для навигации по имени (опционально)
      // Можно использовать Navigator.pushNamed(context, '/main')
      routes: {
        // '/main': (context) => const MainScreen(),
      },
    );
  }
}
