import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fleet_advanced.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Trips & Tours Table
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_no TEXT,
        category TEXT, -- Factory, School, Local Tour, Contract, Advance Booking
        route_details TEXT,
        total_income REAL,
        advance_received REAL,
        fuel_expense REAL,
        other_expense REAL,
        trip_date TEXT,
        last_edited TEXT
      )
    ''');

    // 2. Maintenance & Oil Change Engine
    await db.execute('''
      CREATE TABLE maintenance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_no TEXT,
        type TEXT, -- Oil Change, Tyre, Engine Repair, Tuning
        meter_reading INTEGER,
        next_due_km INTEGER,
        cost REAL,
        vendor_name TEXT,
        date TEXT
      )
    ''');

    // 3. Reminders & Document Alerts
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_no TEXT,
        title TEXT, -- Token Tax, Route Permit, Fitness, Insurance
        due_date TEXT,
        status TEXT DEFAULT 'Pending'
      )
    ''');
  }

  // UPDATE / EDIT ENTRY
  Future<int> updateTrip(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('trips', row, where: 'id = ?', whereArgs: [id]);
  }
}
