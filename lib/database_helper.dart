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
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS fuel_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              vehicle_number TEXT NOT NULL,
              date TEXT NOT NULL,
              rate REAL NOT NULL,
              liters REAL NOT NULL,
              total_cost REAL NOT NULL,
              odometer REAL
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS maintenance_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              vehicle_number TEXT NOT NULL,
              date TEXT NOT NULL,
              work_description TEXT NOT NULL,
              cost REAL NOT NULL,
              mechanic_name TEXT
            )
          ''');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        number TEXT UNIQUE NOT NULL,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE drivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        license TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer TEXT,
        phone TEXT,
        destination TEXT,
        date TEXT,
        amount REAL,
        status TEXT
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
        date TEXT NOT NULL,
        amount REAL,
        status TEXT DEFAULT 'Pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE fuel_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_number TEXT NOT NULL,
        date TEXT NOT NULL,
        rate REAL NOT NULL,
        liters REAL NOT NULL,
        total_cost REAL NOT NULL,
        odometer REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_number TEXT NOT NULL,
        date TEXT NOT NULL,
        work_description TEXT NOT NULL,
        cost REAL NOT NULL,
        mechanic_name TEXT
      )
    ''');
  }

  // --- Generic Helper Methods ---
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    final db = await instance.database;
    return await db.query(table, orderBy: 'id DESC');
  }

  Future<int> insertRecord(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(table, data);
  }

  Future<int> updateRecord(String table, Map<String, dynamic> data, int id) async {
    final db = await instance.database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecord(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // --- Vendor Specific Methods ---
  Future<List<Map<String, dynamic>>> getVendors() async {
    return await fetchAll('vendors');
  }

  Future<int> addVendor(Map<String, dynamic> data) async {
    return await insertRecord('vendors', data);
  }

  Future<int> updateVendor(int id, Map<String, dynamic> data) async {
    return await updateRecord('vendors', data, id);
  }

  Future<int> deleteVendor(int id) async {
    return await deleteRecord('vendors', id);
  }

  // --- Reminder Specific Methods ---
  Future<List<Map<String, dynamic>>> getReminders() async {
    return await fetchAll('reminders');
  }

  Future<int> addReminder(Map<String, dynamic> data) async {
    return await insertRecord('reminders', data);
  }

  Future<int> updateReminder(int id, Map<String, dynamic> data) async {
    return await updateRecord('reminders', data, id);
  }

  Future<int> deleteReminder(int id) async {
    return await deleteRecord('reminders', id);
  }

  // --- Vehicle Linked Merged Query ---
  Future<List<Map<String, dynamic>>> getLogsByVehicle(String vehicleNumber, String table) async {
    final db = await instance.database;
    return await db.query(table, where: 'vehicle_number = ?', whereArgs: [vehicleNumber], orderBy: 'id DESC');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

