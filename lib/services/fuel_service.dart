import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/fuel_log_model.dart';

class FuelService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 1. Add Fuel Record
  Future<int> addFuelLog(FuelLog log) async {
    final db = await _dbHelper.database;
    return await db.insert('fuel_logs', log.toMap());
  }

  // 2. Edit / Update Fuel Record
  Future<int> updateFuelLog(FuelLog log) async {
    final db = await _dbHelper.database;
    return await db.update(
      'fuel_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  // 3. Delete Fuel Record
  Future<int> deleteFuelLog(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('fuel_logs', where: 'id = ?', whereArgs: [id]);
  }

  // 4. Get Fuel Logs by Vehicle
  Future<List<FuelLog>> getFuelByVehicle(int vehicleId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'fuel_logs',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return res.map((e) => FuelLog.fromMap(e)).toList();
  }

  // 5. Get Fuel Logs by Booking
  Future<List<FuelLog>> getFuelByBooking(int bookingId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'fuel_logs',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
      orderBy: 'date DESC',
    );
    return res.map((e) => FuelLog.fromMap(e)).toList();
  }

  // 6. Monthly Report Method
  Future<Map<String, double>> getMonthlyVehicleReport({
    required int vehicleId,
    required String monthYear,
  }) async {
    final db = await _dbHelper.database;

    final earningRes = await db.rawQuery('''
      SELECT SUM(total_amount) as total FROM bookings 
      WHERE vehicle_id = ? AND strftime('%Y-%m', booking_date) = ?
    ''', [vehicleId, monthYear]);
    double earning = (earningRes.first['total'] as num?)?.toDouble() ?? 0.0;

    final fuelRes = await db.rawQuery('''
      SELECT SUM(total_cost) as total FROM fuel_logs 
      WHERE vehicle_id = ? AND strftime('%Y-%m', date) = ?
    ''', [vehicleId, monthYear]);
    double fuel = (fuelRes.first['total'] as num?)?.toDouble() ?? 0.0;

    final expRes = await db.rawQuery('''
      SELECT SUM(amount) as total FROM vehicle_expenses 
      WHERE vehicle_id = ? AND strftime('%Y-%m', date) = ?
    ''', [vehicleId, monthYear]);
    double otherExp = (expRes.first['total'] as num?)?.toDouble() ?? 0.0;

    double netProfit = earning - (fuel + otherExp);

    return {
      'earning': earning,
      'fuel': fuel,
      'otherExp': otherExp,
      'netProfit': netProfit,
    };
  }
}
