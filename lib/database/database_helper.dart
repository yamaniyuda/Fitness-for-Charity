import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await init();
    return _db!;
  }

  Future<Database> init() async {
    if (kIsWeb) {
      final factory = databaseFactoryFfiWeb;
      return await factory.openDatabase('auth.db',
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');
            },
          ));
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'auth.db');
      return await openDatabase(path, version: 1, onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');
      });
    }
  }

  Future<bool> createUser(String email, String password) async {
    try {
      final dbClient = await db;
      final id = await dbClient.insert('users', {'email': email, 'password': password});
      return id > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> userExists(String email) async {
    final dbClient = await db;
    final res = await dbClient.query('users', where: 'email = ?', whereArgs: [email]);
    return res.isNotEmpty;
  }

  Future<bool> validateUser(String email, String password) async {
    final dbClient = await db;
    final res = await dbClient.query('users',
        where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return res.isNotEmpty;
  }
}
