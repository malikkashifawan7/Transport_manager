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
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL,
        driver_name TEXT,
        driver_phone TEXT,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER,
        type TEXT,
        sub_category TEXT,
        title TEXT,
        amount REAL,
        party_name TEXT,
        date TEXT
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

  // Vehicles CRUD
  Future<int> addVehicle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('vehicles', row);
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles', orderBy: 'id DESC');
  }

  Future<int> updateVehicle(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('vehicles', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await instance.database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // Records CRUD
  Future<int> addRecord(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('records', row);
  }

  Future<List<Map<String, dynamic>>> getRecords(int? vehicleId) async {
    final db = await instance.database;
    if (vehicleId == null) {
      return await db.query('records', orderBy: 'id DESC');
    }
    return await db.query('records', where: 'vehicle_id = ?', whereArgs: [vehicleId], orderBy: 'id DESC');
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  // Notes CRUD (Added missing methods)
  Future<int> addNote(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('notes', row);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await instance.database;
    return await db.query('notes', orderBy: 'id DESC');
  }

  Future<int> updateNote(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('notes', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
