import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_erp_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS vehicles');
        await db.execute('DROP TABLE IF EXISTS records');
        await db.execute('DROP TABLE IF EXISTS vendors');
        await db.execute('DROP TABLE IF EXISTS reminders');
        await db.execute('DROP TABLE IF EXISTS bookings');
        await _createDB(db, newVersion);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL,
        type TEXT,
        model TEXT,
        driver_name TEXT,
        driver_phone TEXT,
        driver_cnic TEXT,
        location TEXT,
        status TEXT DEFAULT 'Active'
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
        balance REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT,
        status TEXT DEFAULT 'Pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_number TEXT,
        client TEXT,
        route TEXT,
        amount REAL,
        date TEXT,
        status TEXT DEFAULT 'Booked'
      )
    ''');
  }

  // Vehicles
  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles', orderBy: 'id DESC');
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

  // Records
  Future<List<Map<String, dynamic>>> getRecords(int? vehicleId) async {
    final db = await instance.database;
    if (vehicleId != null) {
      return await db.query('records', where: 'vehicle_id = ?', orderBy: 'id DESC', whereArgs: [vehicleId]);
    }
    return await db.query('records', orderBy: 'id DESC');
  }

  // Bookings
  Future<List<Map<String, dynamic>>> getBookings(dynamic filter) async {
    final db = await instance.database;
    return await db.query('bookings', orderBy: 'id DESC');
  }

  Future<int> addBooking(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('bookings', row);
  }

  Future<int> deleteBooking(int id) async {
    final db = await instance.database;
    return await db.delete('bookings', where: 'id = ?', whereArgs: [id]);
  }

  // Vendors
  Future<List<Map<String, dynamic>>> getVendors() async {
    final db = await instance.database;
    return await db.query('vendors', orderBy: 'id DESC');
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

  // Reminders
  Future<List<Map<String, dynamic>>> getReminders() async {
    final db = await instance.database;
    return await db.query('reminders', orderBy: 'id DESC');
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
