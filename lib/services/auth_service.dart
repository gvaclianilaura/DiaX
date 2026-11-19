import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _authKey = 'is_logged_in';
  static const String _userIdKey = 'user_id'; // Новый ключ для хранения ID

  // Проверяем, авторизован ли пользователь
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authKey) ?? false;
  }

  // Получаем ID текущего пользователя для отправки на сервер
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Сохраняем успешный вход с конкретным ID
  static Future<void> login(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, true);
    await prefs.setInt(_userIdKey, userId); // Запоминаем, кто именно вошел
  }

  // Очищаем данные при выходе
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, false);
    await prefs.remove(_userIdKey); // Удаляем ID
  }
}