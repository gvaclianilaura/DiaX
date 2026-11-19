import 'dart:convert';
import 'dart:io'; // Обязательный импорт для работы с файлами (File)
import 'package:http/http.dart' as http;
import 'package:diax/models/saved_calculation.dart';
import 'package:diax/models/calendar_event.dart'; // Импортируем модель календаря

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Регистрация нового пользователя
  static Future<int?> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user_id']; // Возвращаем ID нового юзера
      } else {
        print('Ошибка регистрации: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Ошибка сети при регистрации: $e');
      return null;
    }
  }

  // Вход существующего пользователя
  static Future<int?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user_id']; // Возвращаем ID найденного юзера
      } else {
        print('Ошибка входа: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Ошибка сети при входе: $e');
      return null;
    }
  }

  // Загрузка фото на сервер (для отправки в Cloud.ru через редирект бэкенда)
  static Future<String?> uploadPhoto(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);
      
      if (data['status'] == 'ok') {
        return data['image_url']; // Возвращаем ссылку на эндпоинт редиректа
      }
      print('Ошибка сервера при загрузке фото: ${data['message']}');
      return null;
    } catch (e) {
      print('Ошибка сети при отправке фото: $e');
      return null;
    }
  }

  // Метод POST: Сохраняем расчет в облако
  static Future<bool> saveRecord({
    required int userId,
    String? productName,
    required double carbsPer100,
    required double weight,
    required double breadUnits,
    required double carbsInPortion,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/records'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'product_name': productName ?? '',
          'carbs_per_100': carbsPer100,
          'weight': weight,
          'bread_units': breadUnits,
          'carbs_in_portion': carbsInPortion,
          'image_url': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Ошибка сервера: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Ошибка сети: $e');
      return false;
    }
  }

  // Метод GET: Получаем список расчетов из облака
  static Future<List<SavedCalculation>> getUserRecords(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/records/$userId'));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List recordsJson = decoded['records'] ?? [];

        return recordsJson.map((json) => SavedCalculation(
          id: json['id'],
          createdAt: json['created_at'],
          productName: json['product_name'] ?? '',
          carbsPer100: (json['carbs_per_100'] as num).toDouble(),
          weight: (json['weight'] as num).toDouble(),
          breadUnits: (json['bread_units'] as num).toDouble(),
          carbsInPortion: (json['carbs_in_portion'] as num).toDouble(),
          photoPath: json['image_url'], 
        )).toList();
      } else {
        print('Ошибка сервера: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Ошибка получения данных: $e');
      return [];
    }
  }

  // Метод DELETE: Удаляем расчет
  static Future<bool> deleteRecord(int recordId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/records/$recordId'));
      
      if (response.statusCode == 200) {
        return true; 
      } else {
        print('Ошибка удаления: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Ошибка сети при удалении: $e');
      return false;
    }
  }

  // --- МЕТОДЫ ДЛЯ КАЛЕНДАРЯ ---

  // Создание события в календаре
  static Future<bool> createCalendarEvent(CalendarEvent event) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calendar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(event.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Ошибка сохранения события: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Ошибка сети при сохранении события: $e');
      return false;
    }
  }

  // Получение всех событий календаря для пользователя
  static Future<List<CalendarEvent>> getCalendarEvents(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/calendar/$userId'));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List eventsJson = decoded['events'] ?? [];
        
        return eventsJson.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        print('Ошибка получения событий календаря: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Ошибка сети при получении календаря: $e');
      return [];
    }
  }
}