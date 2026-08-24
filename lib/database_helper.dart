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
        model TEXT,
        type TEXT,
        driver_name TEXT,
        driver_phone TEXT,
        driver_cnic TEXT,
        location TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER,
        type TEXT,
        main_category TEXT,
        sub_category TEXT,
        title TEXT,
        amount REAL,
        details TEXT,
        meter_reading REAL,
        litres REAL,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER,
        party_name TEXT,
        route_from TEXT,
        route_to TEXT,
        total_freight REAL,
        advance_paid REAL,
        commission REAL,
        booking_date TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        shop_name TEXT,
        phone TEXT,
        address TEXT,
        city TEXT,
        udhar_balance REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        due_date TEXT,
        type TEXT,
        details TEXT
      )
    ''');
  }

  // Vehicles CRUD
  Future<int> addVehicle(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('vehicles', data);
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles');
  }

  Future<int> updateVehicle(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('vehicles', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await instance.database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // Records CRUD
  Future<int> addRecord(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('records', data);
  }

  Future<List<Map<String, dynamic>>> getRecords(int vehicleId) async {
    final db = await instance.database;
    return await db.query('records', where: 'vehicle_id = ?', whereArgs: [vehicleId]);
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  // Bookings CRUD
  Future<int> addBooking(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('bookings', data);
  }

  Future<List<Map<String, dynamic>>> getBookings(int? vehicleId) async {
    final db = await instance.database;
    if (vehicleId != null) {
      return await db.query('bookings', where: 'vehicle_id = ?', whereArgs: [vehicleId]);
    }
    return await db.query('bookings');
  }

  // Vendors CRUD
  Future<int> addVendor(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('vendors', data);
  }

  Future<List<Map<String, dynamic>>> getVendors() async {
    final db = await instance.database;
    return await db.query('vendors');
  }

  // Reminders CRUD
  Future<int> addReminder(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('reminders', data);
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final db = await instance.database;
    return await db.query('reminders');
  }
}
