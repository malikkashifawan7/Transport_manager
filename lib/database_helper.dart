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
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL,
        driver_name TEXT,
        model TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER,
        date TEXT,
        type TEXT,
        sub_category TEXT,
        title TEXT,
        amount REAL,
        litres REAL,
        meter_reading REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        type TEXT,
        balance REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        client TEXT,
        amount REAL,
        date TEXT
      )
    ''');
  }

  // --- VEHICLES METHODS ---
  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles');
  }

  Future<int> addVehicle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('vehicles', row);
  }

  Future<int> updateVehicle(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('vehicles', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await instance.database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // --- RECORDS METHODS ---
  Future<List<Map<String, dynamic>>> getRecords(int? vehicleId) async {
    final db = await instance.database;
    if (vehicleId != null) {
      return await db.query('records', where: 'vehicle_id = ?', whereArgs: [vehicleId]);
    }
    return await db.query('records');
  }

  // --- BOOKINGS METHODS ---
  Future<List<Map<String, dynamic>>> getBookings(dynamic filter) async {
    final db = await instance.database;
    return await db.query('bookings');
  }

  // --- VENDORS METHODS ---
  Future<List<Map<String, dynamic>>> getVendors() async {
    final db = await instance.database;
    return await db.query('vendors');
  }

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

  // --- REMINDERS METHODS ---
  Future<List<Map<String, dynamic>>> getReminders() async {
    final db = await instance.database;
    return await db.query('reminders');
  }

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
}

