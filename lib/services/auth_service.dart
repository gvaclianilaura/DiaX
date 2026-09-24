import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _authKey = 'is_logged_in';

  // Проверяем, авторизован ли пользователь
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authKey) ?? false; // Если данных нет, вернет false
  }

  // Сохраняем успешный вход/регистрацию
  static Future<void> login() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, true);
  }

  // Для кнопки "Выйти"
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, false);
  }
}