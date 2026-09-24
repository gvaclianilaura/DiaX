import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица пользователей.
    // login UNIQUE — не даст создать двух одинаковых логинов.
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        login TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Таблица настроек.
    // unit: 0 - ммоль/л, 1 - мг/дл
    await db.execute('''
      CREATE TABLE settings (
        user_id INTEGER PRIMARY KEY,
        unit INTEGER DEFAULT 0,
        snack_time TEXT DEFAULT '14:00',
        measure_time TEXT DEFAULT '08:00'
      )
    ''');
  }

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

  /// Проверка логина/пароля (для будущего экрана входа).
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

  /// Все пользователи (пригодится для отладки / просмотра БД).
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return db.query('users');
  }

  // --- МЕТОДЫ ДЛЯ НАСТРОЕК ---

  /// Сохранить или обновить настройки
  Future<void> saveSettings(int userId, int unit, String snackTime, String measureTime) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'user_id': userId,
        'unit': unit,
        'snack_time': snackTime,
        'measure_time': measureTime,
      },
      // Перезаписываем настройки, если они уже есть для этого пользователя
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
}