import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DBHelper {
  DBHelper._();
  static final DBHelper instance = DBHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // NOTE: bump version to 2 so onUpgrade will run if DB exists
    const dbVersion = 2;

    if (kIsWeb) {
      // Web
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        'auth_web.db',
        options: OpenDatabaseOptions(
          version: dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dbPath = await databaseFactory.getDatabasesPath();
      return await databaseFactory.openDatabase(
        join(dbPath, 'auth_desktop.db'),
        options: OpenDatabaseOptions(
          version: dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      // Android / iOS
      final dbPath = await getDatabasesPath();
      return await openDatabase(
        join(dbPath, 'auth.db'),
        version: dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // existing users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');

    // new tables: authors, categories, cards
    await db.execute('''
      CREATE TABLE authors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        avatar TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT,
        body TEXT,
        imageUrl TEXT,
        event_date INTEGER,
        latitude REAL,
        longitude REAL,
        target_donation REAL DEFAULT 0,
        collected_donation REAL DEFAULT 0,
        favorite INTEGER DEFAULT 0,
        created_at INTEGER,
        author_id INTEGER,
        category_id INTEGER,
        FOREIGN KEY(author_id) REFERENCES authors(id) ON DELETE SET NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // if upgrading from v1 -> v2 add new tables (safe - IF NOT EXISTS)
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS authors (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          avatar TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS cards (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          subtitle TEXT,
          body TEXT,
          imageUrl TEXT,
          event_date INTEGER,
          latitude REAL,
          longitude REAL,
          target_donation REAL DEFAULT 0,
          collected_donation REAL DEFAULT 0,
          favorite INTEGER DEFAULT 0,
          created_at INTEGER,
          author_id INTEGER,
          category_id INTEGER
        )
      ''');
    }
  }

  // --------- User functions (kept) ----------
  Future<bool> createUser(String email, String password) async {
    try {
      final dbClient = await database;
      final id = await dbClient.insert('users', {
        'email': email,
        'password': password,
      });
      return id > 0;
    } catch (e) {
      debugPrint('Error createUser: $e');
      return false;
    }
  }

  Future<bool> userExists(String email) async {
    final dbClient = await database;
    final result = await dbClient.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<bool> validateUser(String email, String password) async {
    final dbClient = await database;
    final result = await dbClient.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty;
  }

  // --------- Authors & Categories ----------
  Future<int> insertAuthor(Map<String, dynamic> author) async {
    final dbClient = await database;
    // ignore conflicts (if same name) to avoid duplicates
    return await dbClient.insert('authors', author, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final dbClient = await database;
    return await dbClient.insert('categories', category, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int?> getCategoryIdByName(String name) async {
    final db = await database;
    final res = await db.query('categories', where: 'name = ?', whereArgs: [name], limit: 1);
    if (res.isEmpty) return null;
    return res.first['id'] as int?;
  }

  Future<int?> getAuthorIdByName(String name) async {
    final db = await database;
    final res = await db.query('authors', where: 'name = ?', whereArgs: [name], limit: 1);
    if (res.isEmpty) return null;
    return res.first['id'] as int?;
  }

  Future<List<Map<String, dynamic>>> getAllAuthors() async {
    final db = await database;
    return await db.query('authors', orderBy: 'name COLLATE NOCASE');
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name COLLATE NOCASE');
  }

  // --------- Cards CRUD ----------
  Future<int> insertCard(Map<String, dynamic> card) async {
    final dbClient = await database;
    return await dbClient.insert('cards', card);
  }

  Future<int> updateCard(int id, Map<String, dynamic> values) async {
    final dbClient = await database;
    return await dbClient.update('cards', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCard(int id) async {
    final dbClient = await database;
    return await dbClient.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> setFavorite(int id, bool fav) async {
    final dbClient = await database;
    return await dbClient.update('cards', {'favorite': fav ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getCardById(int id) async {
    final db = await database;
    final res = await db.query('cards', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;
    return res.first;
  }

  // returns rows with author_name and category_name included
  Future<List<Map<String, dynamic>>> getCardsWithMeta({String? search, bool onlyFav = false}) async {
    final dbClient = await database;
    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      whereParts.add('(c.title LIKE ? OR c.subtitle LIKE ? OR c.body LIKE ?)');
      whereArgs.addAll([s, s, s]);
    }
    if (onlyFav) {
      whereParts.add('c.favorite = 1');
    }

    final whereClause = whereParts.isEmpty ? '' : 'WHERE ' + whereParts.join(' AND ');

    final sql = '''
      SELECT c.*, a.name AS author_name, a.avatar AS author_avatar, cat.name AS category_name
      FROM cards c
      LEFT JOIN authors a ON c.author_id = a.id
      LEFT JOIN categories cat ON c.category_id = cat.id
      $whereClause
      ORDER BY c.event_date DESC, c.created_at DESC
    ''';

    final res = await dbClient.rawQuery(sql, whereArgs);
    return res;
  }

  // convenience search wrapper
  Future<List<Map<String, dynamic>>> searchCards(String query) async {
    return await getCardsWithMeta(search: query);
  }
}
