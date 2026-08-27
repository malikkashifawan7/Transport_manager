import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_app.db');
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
      CREATE TABLE maintenance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleNo TEXT,
        serviceType TEXT,
        cost REAL,
        date TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT,
        phone TEXT,
        totalAmount REAL,
        advanceAmount REAL,
        remainingAmount REAL,
        bookingDate TEXT,
        vehicleNo TEXT
      )
    ''');
  }

  Future<int> insertRecord(String table, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    final db = await instance.database;
    return await db.query(table, orderBy: 'id DESC');
  }

  Future<int> deleteRecord(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
