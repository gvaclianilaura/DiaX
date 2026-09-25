// Простой smoke-тест: проверяем, что приложение запускается без ошибок.
// Если понадобится писать настоящие тесты — замените содержимое.

import 'package:flutter_test/flutter_test.dart';

import 'package:diax/main.dart';

void main() {
  testWidgets('Приложение запускается без ошибок', (WidgetTester tester) async {
    // Запускаем приложение
    await tester.pumpWidget(const MyApp());

    // Даём время на первую отрисовку
    await tester.pump();

    // Проверяем, что MaterialApp построился
    expect(find.byType(MyApp), findsOneWidget);
  });
}
