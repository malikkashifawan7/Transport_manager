import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_erp.db');
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
    // Vehicles Table
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleNumber TEXT NOT NULL UNIQUE,
        model TEXT,
        driverName TEXT,
        driverPhone TEXT
      )
    ''');

    // Vendors & Khata Table
    await db.execute('''
      CREATE TABLE khata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleNumber TEXT NOT NULL,
        vendorName TEXT NOT NULL,
        description TEXT,
        udhar REAL DEFAULT 0.0,
        jama REAL DEFAULT 0.0,
        baqaya REAL DEFAULT 0.0,
        date TEXT NOT NULL
      )
    ''');

    // Bookings Table
    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        partyName TEXT NOT NULL,
        phone TEXT NOT NULL,
        route TEXT NOT NULL,
        vehicleNumber TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        advance REAL NOT NULL,
        balance REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  // Helper Methods required by screens
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<int> insertRecord(String table, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(table, row);
  }

  Future<int> updateRecord(String table, Map<String, dynamic> row, int id) async {
    final db = await instance.database;
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecord(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
