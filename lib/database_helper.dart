import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_elite_erp_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL,
        type TEXT,
        driver_name TEXT,
        driver_phone TEXT,
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
        meter_reading REAL,
        party_name TEXT,
        payment_status TEXT DEFAULT 'Paid'
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_number TEXT,
        client TEXT,
        route TEXT,
        amount REAL,
        advance REAL,
        date TEXT,
        status TEXT DEFAULT 'Pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        date TEXT
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

  // Records & Ledger
  Future<List<Map<String, dynamic>>> getRecords(int? vehicleId) async {
    final db = await instance.database;
    if (vehicleId != null) {
      return await db.query('records', where: 'vehicle_id = ?', orderBy: 'id DESC', whereArgs: [vehicleId]);
    }
    return await db.query('records', orderBy: 'id DESC');
  }

  Future<int> addRecord(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('records', row);
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  // Bookings
  Future<List<Map<String, dynamic>>> getBookings() async {
    final db = await instance.database;
    return await db.query('bookings', orderBy: 'id DESC');
  }

  Future<int> addBooking(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('bookings', row);
  }

  // Notes & Reminders
  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await instance.database;
    return await db.query('notes', orderBy: 'id DESC');
  }

  Future<int> addNote(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('notes', row);
  }
}
