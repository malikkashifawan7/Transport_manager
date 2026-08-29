import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_manager_v5.db'); // New DB instance to bypass legacy cache
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS vehicles');
        await db.execute('DROP TABLE IF EXISTS drivers');
        await db.execute('DROP TABLE IF EXISTS bookings');
        await db.execute('DROP TABLE IF EXISTS vendors');
        await db.execute('DROP TABLE IF EXISTS vendor_transactions');
        await db.execute('DROP TABLE IF EXISTS fuel_logs');
        await db.execute('DROP TABLE IF EXISTS maintenance_logs');
        await _createDB(db, 5);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT UNIQUE NOT NULL,
        type TEXT,
        driver_name TEXT,
        driver_phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE drivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        license TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer TEXT NOT NULL,
        phone TEXT,
        destination TEXT,
        date TEXT,
        total_amount REAL DEFAULT 0.0,
        advance_amount REAL DEFAULT 0.0,
        baqaya_amount REAL DEFAULT 0.0,
        status TEXT DEFAULT 'Pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        type TEXT,
        total_jama REAL DEFAULT 0.0,
        total_udhar REAL DEFAULT 0.0,
        balance REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE vendor_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendor_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        FOREIGN KEY (vendor_id) REFERENCES vendors (id) ON DELETE CASCADE
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

  // --- Safe Helper Methods ---
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    final db = await instance.database;
    return await db.query(table, orderBy: 'id DESC');
  }

  Future<int> insertRecord(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateRecord(String table, Map<String, dynamic> data, int id) async {
    final db = await instance.database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecord(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getLogsByVehicle(String vehicleNumber, String table) async {
    final db = await instance.database;
    return await db.query(table, where: 'vehicle_number = ?', whereArgs: [vehicleNumber], orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getVendors() async => fetchAll('vendors');
  Future<int> addVendor(Map<String, dynamic> data) async => insertRecord('vendors', data);
  Future<int> updateVendor(int id, Map<String, dynamic> data) async => updateRecord('vendors', data, id);
  Future<int> deleteVendor(int id) async => deleteRecord('vendors', id);

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
