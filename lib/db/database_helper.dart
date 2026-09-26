import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:diax/models/meal_entry.dart';
import 'package:diax/models/saved_calculation.dart';

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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // === Пользователи ===
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        login TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // === Настройки ===
    await db.execute('''
      CREATE TABLE settings (
        user_id INTEGER PRIMARY KEY,
        unit INTEGER DEFAULT 0,
        snack_time TEXT DEFAULT '14:00',
        measure_time TEXT DEFAULT '08:00'
      )
    ''');

    // === Записи о еде ===
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

    // === Напоминания ===
    // type: 'measure' — измерение сахара, 'snack' — перекус
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        time TEXT NOT NULL,
        enabled INTEGER DEFAULT 1
      )
    ''');

    // === Сохранённые расчёты ХЕ ===
    await db.execute('''
      CREATE TABLE saved_calculations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        product_name TEXT DEFAULT '',
        carbs_per_100 REAL NOT NULL,
        weight REAL NOT NULL,
        bread_units REAL NOT NULL,
        carbs_in_portion REAL NOT NULL,
        photo_path TEXT
      )
    ''');
  }

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
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          time TEXT NOT NULL,
          enabled INTEGER DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS saved_calculations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          created_at TEXT NOT NULL,
          product_name TEXT DEFAULT '',
          carbs_per_100 REAL NOT NULL,
          weight REAL NOT NULL,
          bread_units REAL NOT NULL,
          carbs_in_portion REAL NOT NULL,
          photo_path TEXT
        )
      ''');
    }
  }

  // ==================== ПОЛЬЗОВАТЕЛИ ====================

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

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return db.query('users');
  }

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

  Future<Map<String, dynamic>?> getSettings(int userId) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // ==================== ЗАПИСИ О ЕДЕ ====================

  Future<void> saveMealEntry(MealEntry entry) async {
    final db = await database;
    await db.insert(
      'meal_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<List<MealEntry>> getMealEntriesForDate(String date) async {
    final db = await database;
    final result = await db.query(
      'meal_entries',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((map) => MealEntry.fromMap(map)).toList();
  }

  Future<void> deleteMealEntry(String date, String mealName) async {
    final db = await database;
    await db.delete(
      'meal_entries',
      where: 'date = ? AND meal_name = ?',
      whereArgs: [date, mealName],
    );
  }

  // ==================== НАПОМИНАНИЯ ====================

  Future<int> addReminder(int userId, String type, String time) async {
    final db = await database;
    return await db.insert('reminders', {
      'user_id': userId,
      'type': type,
      'time': time,
      'enabled': 1,
    });
  }

  Future<List<Map<String, dynamic>>> getReminders(
    int userId,
    String type,
  ) async {
    final db = await database;
    return db.query(
      'reminders',
      where: 'user_id = ? AND type = ?',
      whereArgs: [userId, type],
      orderBy: 'time ASC',
    );
  }

  Future<void> updateReminder(int id, String newTime) async {
    final db = await database;
    await db.update(
      'reminders',
      {'time': newTime},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteReminder(int id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllReminders(int userId, String type) async {
    final db = await database;
    await db.delete(
      'reminders',
      where: 'user_id = ? AND type = ?',
      whereArgs: [userId, type],
    );
  }

  // ==================== СОХРАНЁННЫЕ РАСЧЁТЫ ХЕ ====================

  Future<int> saveCalculation(SavedCalculation calc) async {
    final db = await database;
    return await db.insert('saved_calculations', calc.toMap());
  }

  Future<List<SavedCalculation>> getAllCalculations() async {
    final db = await database;
    final result = await db.query(
      'saved_calculations',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => SavedCalculation.fromMap(map)).toList();
  }

  Future<void> deleteCalculation(int id) async {
    final db = await database;
    await db.delete('saved_calculations', where: 'id = ?', whereArgs: [id]);
  }
}
