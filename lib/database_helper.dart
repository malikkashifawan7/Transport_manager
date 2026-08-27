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
    // Vehicles Table (Linked with Driver)
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleNumber TEXT NOT NULL UNIQUE,
        model TEXT,
        driverName TEXT,
        driverPhone TEXT
      )
    ''');

    // Vendors & Khata Table (Linked by Vehicle Number)
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
}
