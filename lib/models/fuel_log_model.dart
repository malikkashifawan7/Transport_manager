class FuelLog {
  final int? id;
  final int vehicleId;
  final int? bookingId;
  final String fuelType; // 'Diesel', 'Petrol', 'LPG'
  final double ratePerUnit;
  final double totalUnits;
  final double totalCost;
  final String date;
  final String? notes;

  FuelLog({
    this.id,
    required this.vehicleId,
    this.bookingId,
    required this.fuelType,
    required this.ratePerUnit,
    required this.totalUnits,
    required this.totalCost,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'booking_id': bookingId,
      'fuel_type': fuelType,
      'rate_per_unit': ratePerUnit,
      'total_units': totalUnits,
      'total_cost': totalCost,
      'date': date,
      'notes': notes,
    };
  }

  factory FuelLog.fromMap(Map<String, dynamic> map) {
    return FuelLog(
      id: map['id'],
      vehicleId: map['vehicle_id'],
      bookingId: map['booking_id'],
      fuelType: map['fuel_type'],
      ratePerUnit: (map['rate_per_unit'] as num).toDouble(),
      totalUnits: (map['total_units'] as num).toDouble(),
      totalCost: (map['total_cost'] as num).toDouble(),
      date: map['date'],
      notes: map['notes'],
    );
  }
}
