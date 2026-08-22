import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> fuelLogs = [];
  List<Map<String, dynamic>> maintenanceLogs = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vehicles = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v3_vehicles') ?? '[]'));
      bookings = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v3_bookings') ?? '[]'));
      fuelLogs = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v3_fuel') ?? '[]'));
      maintenanceLogs = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v3_maint') ?? '[]'));
    });
  }

  Future<void> _saveKey(String key, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  void _showAddVehicleDialog() {
    final numCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final cnicCtrl = TextEditingController();
    final modelCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vehicle & Driver'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: cnicCtrl, decoration: const InputDecoration(labelText: 'Driver CNIC')),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Vehicle Model')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numCtrl.text.isNotEmpty) {
                final newV = {
                  'number': numCtrl.text.toUpperCase(),
                  'driver': driverCtrl.text,
                  'cnic': cnicCtrl.text,
                  'model': modelCtrl.text,
                };
                setState(() => vehicles.add(newV));
                _saveKey('v3_vehicles', vehicles);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openVehicleMasterLedger(Map<String, dynamic> vehicle) {
    final String vNum = vehicle['number'] ?? '';
    
    final vBookings = bookings.where((b) => b['vehicle'] == vNum).toList();
    final vFuel = fuelLogs.where((f) => f['vehicle'] == vNum).toList();
    final vMaint = maintenanceLogs.where((m) => m['vehicle'] == vNum).toList();

    double totalEarned = vBookings.fold(0, (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0') ?? 0));
    double totalFuel = vFuel.fold(0, (sum, item) => sum + (double.tryParse(item['cost']?.toString() ?? '0') ?? 0));
    double totalMaint = vMaint.fold(0, (sum, item) => sum + (double.tryParse(item['cost']?.toString() ?? '0') ?? 0));
    double netBalance = totalEarned - totalFuel - totalMaint;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Vehicle: $vNum')),
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setLedgerState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text('Driver: ${vehicle['driver']} | CNIC: ${vehicle['cnic']}'),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text('Earned: Rs. $totalEarned', style: const TextStyle(color: Colors.green)),
                                Text('Expenses: Rs. ${totalFuel + totalMaint}', style: const TextStyle(color: Colors.red)),
                                Text('Net: Rs. $netBalance', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(onPressed: () => _showAddDetailedTripDialog(vNum, vehicle, setLedgerState), child: const Text('+ Detailed Trip')),
                        ElevatedButton(onPressed: () => _showAddQuickExpenseDialog(vNum, setLedgerState), child: const Text('+ Expense/Repair')),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text('🚩 Trips (Click for Details)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ...vBookings.map((b) => Card(
                          child: ListTile(
                            title: Text('${b['party']} (${b['from']} -> ${b['to']})'),
                            subtitle: Text('Date: ${b['date']} | Advance: Rs. ${b['advance']}'),
                            trailing: Text('Rs. ${b['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            onTap: () => _showTripDetailsModal(b, vehicle),
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddDetailedTripDialog(String vNum, Map<String, dynamic> vehicle, StateSetter setLedgerState) {
    final partyCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final advanceCtrl = TextEditingController();
    final expenseCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Trip Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: partyCtrl, decoration: const InputDecoration(labelText: 'Party Name')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Party Address')),
              TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'From Location')),
              TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'To Location')),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Total Freight Amount'), keyboardType: TextInputType.number),
              TextField(controller: advanceCtrl, decoration: const InputDecoration(labelText: 'Advance Payment Received'), keyboardType: TextInputType.number),
              TextField(controller: expenseCtrl, decoration: const InputDecoration(labelText: 'Trip Expense (Diesel/Toll)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final tripData = {
                'vehicle': vNum,
                'party': partyCtrl.text,
                'address': addressCtrl.text,
                'from': fromCtrl.text,
                'to': toCtrl.text,
                'amount': amountCtrl.text,
                'advance': advanceCtrl.text,
                'expense': expenseCtrl.text,
                'date': DateTime.now().toString().split(' ')[0],
                'time': TimeOfDay.now().format(context),
              };
              setState(() => bookings.add(tripData));
              _saveKey('v3_bookings', bookings);
              setLedgerState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save Trip'),
          )
        ],
      ),
    );
  }

  void _showTripDetailsModal(Map<String, dynamic> trip, Map<String, dynamic> vehicle) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Trip Detail: ${trip['party']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Route: ${trip['from']} to ${trip['to']}'),
            Text('Party Address: ${trip['address']}'),
            Text('Driver: ${vehicle['driver']} (CNIC: ${vehicle['cnic']})'),
            Text('Date/Time: ${trip['date']} ${trip['time']}'),
            Text('Total Amount: Rs. ${trip['amount']}'),
            Text('Advance Paid: Rs. ${trip['advance']}'),
            Text('Trip Expenses: Rs. ${trip['expense']}'),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                final msg = "Trip Invoice%0AVehicle: ${trip['vehicle']}%0AParty: ${trip['party']}%0ARoute: ${trip['from']} to ${trip['to']}%0ATotal: Rs.${trip['amount']}%0AAdvance: Rs.${trip['advance']}";
                launchUrl(Uri.parse("https://wa.me/?text=$msg"));
              },
              icon: const Icon(Icons.share),
              label: const Text('Share to WhatsApp'),
            )
          ],
        ),
      ),
    );
  }

  void _showAddQuickExpenseDialog(String vNum, StateSetter setLedgerState) {
    final workCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Maintenance / Puncture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: workCtrl, decoration: const InputDecoration(labelText: 'Expense Detail')),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final exp = {
                'vehicle': vNum,
                'work': workCtrl.text,
                'cost': costCtrl.text,
                'date': DateTime.now().toString().split(' ')[0],
              };
              setState(() => maintenanceLogs.add(exp));
              _saveKey('v3_maint', maintenanceLogs);
              setLedgerState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save Expense'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transport Manager Enterprise')),
      body: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (ctx, i) => ListTile(
          leading: const Icon(Icons.local_shipping),
          title: Text(vehicles[i]['number']),
          subtitle: Text('Driver: ${vehicles[i]['driver']}'),
          onTap: () => _openVehicleMasterLedger(vehicles[i]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

