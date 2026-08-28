import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Vendors Table
    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        type TEXT,
        balance REAL DEFAULT 0.0
      )
    ''');

    // Reminders Table
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        amount REAL,
        status TEXT DEFAULT 'Pending'
      )
    ''');
  }

  // --- Vendors Methods ---
  Future<List<Map<String, dynamic>>> getVendors() async {
    final db = await instance.database;
    return await db.query('vendors', orderBy: 'id DESC');
  }

  Future<int> addVendor(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('vendors', data);
  }

  Future<int> updateVendor(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('vendors', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVendor(int id) async {
    final db = await instance.database;
    return await db.delete('vendors', where: 'id = ?', whereArgs: [id]);
  }

  // --- Reminders Methods ---
  Future<List<Map<String, dynamic>>> getReminders() async {
    final db = await instance.database;
    return await db.query('reminders', orderBy: 'id DESC');
  }

  Future<int> addReminder(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('reminders', data);
  }

  Future<int> updateReminder(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('reminders', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteReminder(int id) async {
    final db = await instance.database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
