import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:diax/models/meal_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'diax.db');

    return await openDatabase(
      path,
      version: 2, // <-- БЫЛО 1, СТАЛО 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // === Таблица пользователей ===
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        login TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // === Таблица настроек ===
    // unit: 0 - ммоль/л, 1 - мг/дл
    await db.execute('''
      CREATE TABLE settings (
        user_id INTEGER PRIMARY KEY,
        unit INTEGER DEFAULT 0,
        snack_time TEXT DEFAULT '14:00',
        measure_time TEXT DEFAULT '08:00'
      )
    ''');

    // === НОВАЯ Таблица записей о приёмах пищи ===
    await db.execute('''
      CREATE TABLE meal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        meal_name TEXT NOT NULL,
        glucose REAL,
        bread_units REAL,
        insulin REAL,
        note TEXT DEFAULT '',
        UNIQUE(date, meal_name)
      )
    ''');
  }

  // Вызывается, когда у пользователя уже есть БД старой версии.
  // Добавляем только новые таблицы, не трогая существующие.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meal_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          meal_name TEXT NOT NULL,
          glucose REAL,
          bread_units REAL,
          insulin REAL,
          note TEXT DEFAULT '',
          UNIQUE(date, meal_name)
        )
      ''');
    }
  }

  // ==================== ПОЛЬЗОВАТЕЛИ ====================

  /// Регистрация. Возвращает false, если логин уже занят.
  Future<bool> registerUser(String login, String password) async {
    final db = await database;

    final existing = await db.query(
      'users',
      where: 'login = ?',
      whereArgs: [login],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;

    await db.insert('users', {
      'login': login,
      'password': password,
      'created_at': DateTime.now().toIso8601String(),
    });
    return true;
  }

  /// Проверка логина/пароля
  Future<bool> checkUser(String login, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'login = ? AND password = ?',
      whereArgs: [login, password],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Все пользователи (для отладки)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return db.query('users');
  }

  /// Получить ID пользователя по логину и паролю
  Future<int?> getUserId(String login, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['id'],
      where: 'login = ? AND password = ?',
      whereArgs: [login, password],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['id'] as int;
  }

  // ==================== НАСТРОЙКИ ====================

  /// Сохранить или обновить настройки
  Future<void> saveSettings(
    int userId,
    int unit,
    String snackTime,
    String measureTime,
  ) async {
    final db = await database;
    await db.insert('settings', {
      'user_id': userId,
      'unit': unit,
      'snack_time': snackTime,
      'measure_time': measureTime,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Получить настройки пользователя по его ID
  Future<Map<String, dynamic>?> getSettings(int userId) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // ==================== ЗАПИСИ О ПРИЁМАХ ПИЩИ ====================

  /// Сохранить (или перезаписать) запись о приёме пищи
  Future<void> saveMealEntry(MealEntry entry) async {
    final db = await database;
    await db.insert(
      'meal_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Загрузить запись по дате и названию приёма пищи
  Future<MealEntry?> getMealEntry(String date, String mealName) async {
    final db = await database;
    final result = await db.query(
      'meal_entries',
      where: 'date = ? AND meal_name = ?',
      whereArgs: [date, mealName],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return MealEntry.fromMap(result.first);
  }

  /// Загрузить все записи на конкретную дату
  Future<List<MealEntry>> getMealEntriesForDate(String date) async {
    final db = await database;
    final result = await db.query(
      'meal_entries',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((map) => MealEntry.fromMap(map)).toList();
  }

  /// Удалить запись
  Future<void> deleteMealEntry(String date, String mealName) async {
    final db = await database;
    await db.delete(
      'meal_entries',
      where: 'date = ? AND meal_name = ?',
      whereArgs: [date, mealName],
    );
  }
}
