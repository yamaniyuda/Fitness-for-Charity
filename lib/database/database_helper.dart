import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await init();
    return _db!;
  }

  Future<Database> init() async {
    if (kIsWeb) {
      final factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        'auth.db',
        options: OpenDatabaseOptions(
          version: 2, // 🔺 bump version to trigger onUpgrade if needed
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE users(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT UNIQUE,
                password TEXT,
                username TEXT,
                country TEXT
              )
            ''');
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute('ALTER TABLE users ADD COLUMN username TEXT');
              await db.execute('ALTER TABLE users ADD COLUMN country TEXT');
            }
          },
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'auth.db');
      return await openDatabase(
        path,
        version: 2, // 🔺 bump version
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT UNIQUE,
              password TEXT,
              username TEXT,
              country TEXT
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE users ADD COLUMN username TEXT');
            await db.execute('ALTER TABLE users ADD COLUMN country TEXT');
          }
        },
      );
    }
  }

  // 🔹 Create user with username and country
  Future<bool> createUser(
      String email, String password, String username, String country) async {
    try {
      final dbClient = await db;
      final id = await dbClient.insert('users', {
        'email': email,
        'password': password,
        'username': username,
        'country': country,
      });
      return id > 0;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  // 🔹 Check if user exists
  Future<bool> userExists(String email) async {
    final dbClient = await db;
    final res =
        await dbClient.query('users', where: 'email = ?', whereArgs: [email]);
    return res.isNotEmpty;
  }

  // 🔹 Validate login (email + password)
  Future<bool> validateUser(String email, String password) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return res.isNotEmpty;
  }

  // 🔹 Get user info (optional helper)
  Future<Map<String, dynamic>?> getUser(String email) async {
    final dbClient = await db;
    final res =
        await dbClient.query('users', where: 'email = ?', whereArgs: [email]);
    if (res.isNotEmpty) return res.first;
    return null;
  }
}
