import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_pro_plus_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final dbPathWithFile = path.join(dbPath, filePath);

    return await openDatabase(
      dbPathWithFile,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL,
        driver_name TEXT,
        driver_phone TEXT,
        type TEXT,
        status TEXT DEFAULT 'Available',
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER,
        type TEXT,
        category TEXT,
        sub_category TEXT,
        title TEXT,
        amount REAL,
        litres REAL,
        meter_reading REAL,
        note TEXT,
        date TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        category TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        due_date TEXT,
        is_completed INTEGER DEFAULT 0
      )
    ''');
  }

  // VEHICLE METHODS
  Future<int> insertVehicle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('vehicles', row);
  }

  Future<int> updateVehicle(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('vehicles', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getVehicles({bool trash = false}) async {
    final db = await instance.database;
    return await db.query('vehicles', where: 'is_deleted = ?', whereArgs: [trash ? 1 : 0]);
  }

  // RECORD / KHATA METHODS (Alias Methods Included)
  Future<int> insertRecord(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('records', row);
  }

  Future<int> addRecord(Map<String, dynamic> row) async {
    return await insertRecord(row);
  }

  Future<int> updateRecord(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('records', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRecords(int? vehicleId, {bool trash = false}) async {
    final db = await instance.database;
    if (vehicleId != null) {
      return await db.query('records', where: 'vehicle_id = ? AND is_deleted = ?', whereArgs: [vehicleId, trash ? 1 : 0]);
    }
    return await db.query('records', where: 'is_deleted = ?', whereArgs: [trash ? 1 : 0]);
  }

  // VENDOR METHODS
  Future<int> addVendor(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('vendors', row);
  }

  Future<int> updateVendor(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('vendors', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVendor(int id) async {
    final db = await instance.database;
    return await db.delete('vendors', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getVendors() async {
    final db = await instance.database;
    return await db.query('vendors');
  }

  // REMINDER METHODS
  Future<int> addReminder(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('reminders', row);
  }

  Future<int> updateReminder(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('reminders', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteReminder(int id) async {
    final db = await instance.database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final db = await instance.database;
    return await db.query('reminders');
  }

  // SOFT & HARD DELETE
  Future<int> setSoftDelete(String table, int id, bool delete) async {
    final db = await instance.database;
    return await db.update(table, {'is_deleted': delete ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> permanentDelete(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
