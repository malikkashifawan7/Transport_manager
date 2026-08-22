import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = "";

  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> drivers = [];
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> fuelLogs = [];
  List<Map<String, dynamic>> maintenanceLogs = [];
  List<Map<String, dynamic>> recycleBin = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vehicles = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v2_vehicles') ?? '[]'));
      drivers = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v2_drivers') ?? '[]'));
      bookings = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v2_bookings') ?? '[]'));
      fuelLogs = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v2_fuel') ?? '[]'));
      maintenanceLogs = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v2_maint') ?? '[]'));
      recycleBin = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v2_trash') ?? '[]'));
    });
  }

  Future<void> _saveKey(String key, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
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
          appBar: AppBar(
            title: Text('Vehicle Account: $vNum'),
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                tooltip: 'Print / Export PDF',
                onPressed: () => _printVehicleLedgerPdf(vNum, vehicle, vBookings, vFuel, vMaint, totalEarned, totalFuel, totalMaint, netBalance),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Driver: ${vehicle['driver'] ?? 'Unassigned'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Model: ${vehicle['model'] ?? '-'}'),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ledgerStatCell('Total Earned', totalEarned, Colors.green),
                            _ledgerStatCell('Fuel Cost', totalFuel, Colors.orange),
                            _ledgerStatCell('Maintenance/Puncture', totalMaint, Colors.red),
                            _ledgerStatCell('Net Profit', netBalance, netBalance >= 0 ? Colors.blue : Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(onPressed: () => _showAddEntryDialog(vNum, 'booking'), icon: const Icon(Icons.add_road), label: const Text('Add Trip')),
                    ElevatedButton.icon(onPressed: () => _showAddEntryDialog(vNum, 'fuel'), icon: const Icon(Icons.local_gas_station), label: const Text('Add Fuel')),
                    ElevatedButton.icon(onPressed: () => _showAddEntryDialog(vNum, 'maint'), icon: const Icon(Icons.build), label: const Text('Add Repair/Puncture')),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('🚩 Trips & Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...vBookings.map((b) => Card(
                      child: ListTile(
                        title: Text('Customer: ${b['customer']} | Route: ${b['route']}'),
                        subtitle: Text('Date: ${b['date']}'),
                        trailing: Text('Rs. ${b['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    )),
                const SizedBox(height: 15),
                const Text('⛽ Fuel Entries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...vFuel.map((f) => Card(
                      child: ListTile(
                        title: Text('${f['liters']} Liters from ${f['pump']}'),
                        subtitle: Text('Date: ${f['date']}'),
                        trailing: Text('Rs. ${f['cost']}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ),
                    )),
                const SizedBox(height: 15),
                const Text('🔧 Maintenance, Punctures & Repairs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...vMaint.map((m) => Card(
                      child: ListTile(
                        title: Text('${m['work']}'),
                        subtitle: Text('Date: ${m['date']}'),
                        trailing: Text('Rs. ${m['cost']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ledgerStatCell(String title, double amount, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11)),
        Text('Rs. ${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _showAddEntryDialog(String vNum, String type) {
    final titleCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'booking' ? 'Add Trip/Booking' : (type == 'fuel' ? 'Add Fuel' : 'Add Repair/Puncture')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: InputDecoration(labelText: type == 'booking' ? 'Route / Customer' : (type == 'fuel' ? 'Liters / Pump Name' : 'Work Detail (e.g. Puncture/Oil)'))),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Amount (PKR)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && costCtrl.text.isNotEmpty) {
                final entry = {
                  'vehicle': vNum,
                  'date': DateTime.now().toString().split(' ')[0],
                  if (type == 'booking') ...{'customer': titleCtrl.text, 'route': titleCtrl.text, 'amount': costCtrl.text},
                  if (type == 'fuel') ...{'liters': '0', 'pump': titleCtrl.text, 'cost': costCtrl.text},
                  if (type == 'maint') ...{'work': titleCtrl.text, 'cost': costCtrl.text},
                };

                setState(() {
                  if (type == 'booking') bookings.add(entry);
                  if (type == 'fuel') fuelLogs.add(entry);
                  if (type == 'maint') maintenanceLogs.add(entry);
                });

                _saveKey('v2_bookings', bookings);
                _saveKey('v2_fuel', fuelLogs);
                _saveKey('v2_maint', maintenanceLogs);
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Save Entry'),
          )
        ],
      ),
    );
  }

  Future<void> _printVehicleLedgerPdf(String vNum, Map<String, dynamic> v, List b, List f, List m, double earn, double fuel, double maint, double net) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("Master Vehicle Ledger - $vNum", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
              pw.Text("Driver: ${v['driver'] ?? 'N/A'} | Model: ${v['model'] ?? 'N/A'}"),
              pw.Divider(),
              pw.Text("SUMMARY: Total Earned: Rs. $earn | Fuel: Rs. $fuel | Repair/Puncture: Rs. $maint | NET PROFIT: Rs. $net"),
              pw.SizedBox(height: 15),
              pw.Text("EXPENSE & REPAIR BREAKDOWN:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Date', 'Type', 'Description', 'Amount (PKR)'],
                  ...m.map((i) => [i['date'].toString(), 'Repair/Puncture', i['work'].toString(), i['cost'].toString()]),
                  ...f.map((i) => [i['date'].toString(), 'Fuel', '${i['liters']}L - ${i['pump']}', i['cost'].toString()]),
                ],
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Manager Pro'),
      ),
      body: _buildVehiclesTab(),
    );
  }

  Widget _buildVehiclesTab() {
    return ListView.builder(
      itemCount: vehicles.length,
      itemBuilder: (ctx, i) {
        final v = vehicles[i];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
            title: Text(v['number'] ?? 'No Number', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('Driver: ${v['driver'] ?? 'N/A'} | Type: ${v['type'] ?? 'Truck'}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openVehicleMasterLedger(v),
          ),
        );
      },
    );
  }
}
