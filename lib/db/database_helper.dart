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
}