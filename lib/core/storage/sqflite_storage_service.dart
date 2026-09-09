import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sqfliteStorageServiceProvider = Provider<SqfliteStorageService>((ref) {
  return SqfliteStorageService();
});

/// SQLite Relational Storage helper for offline Sales Force Automation (SFA) data.
class SqfliteStorageService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'liverestro_sales.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Local restaurant offline cache table
        await db.execute('''
          CREATE TABLE restaurants (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            address TEXT,
            latitude REAL,
            longitude REAL,
            contact_phone TEXT,
            created_at TEXT
          )
        ''');

        // Offline visits sync queue table
        await db.execute('''
          CREATE TABLE offline_visits (
            id TEXT PRIMARY KEY,
            restaurant_id TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            notes TEXT,
            timestamp TEXT NOT NULL,
            is_synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}
