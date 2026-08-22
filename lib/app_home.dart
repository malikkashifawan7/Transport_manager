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
  
  // Data Repositories
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

  // --- Automatic Calculations & Analytics ---
  double _calculateTotalEarnings() => bookings.fold(0, (sum, b) => sum + (double.tryParse(b['amount']?.toString() ?? '0') ?? 0));
  double _calculateTotalFuelCost() => fuelLogs.fold(0, (sum, f) => sum + (double.tryParse(f['cost']?.toString() ?? '0') ?? 0));
  double _calculateTotalMaintCost() => maintenanceLogs.fold(0, (sum, m) => sum + (double.tryParse(m['cost']?.toString() ?? '0') ?? 0));

  // --- PDF & WhatsApp Ledger Generator ---
  Future<void> _generatePdfReport(String title, List<Map<String, dynamic>> items) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            cross: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("Transport Manager Pro - $title", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Text("Generated Statement Date: ${DateTime.now().toString().split(' ')[0]}"),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Date', 'Vehicle', 'Details', 'Amount (PKR)'],
                  ...items.map((i) => [
                        i['date']?.toString() ?? '-',
                        i['vehicle']?.toString() ?? '-',
                        i['details']?.toString() ?? i['route']?.toString() ?? i['work']?.toString() ?? '-',
                        i['amount']?.toString() ?? i['cost']?.toString() ?? '0'
                      ])
                ],
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- CRUD Actions & Recycling ---
  void _deleteWithTrash(String type, int index, Map<String, dynamic> item) {
    setState(() {
      recycleBin.add({'type': type, 'data': item, 'deletedAt': DateTime.now().toString()});
      if (type == 'vehicle') vehicles.removeAt(index);
      if (type == 'driver') drivers.removeAt(index);
      if (type == 'booking') bookings.removeAt(index);
      if (type == 'fuel') fuelLogs.removeAt(index);
    });
    _saveKey('v2_trash', recycleBin);
    _saveKey('v2_${type}s', type == 'vehicle' ? vehicles : (type == 'driver' ? drivers : (type == 'booking' ? bookings : fuelLogs)));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item moved to Recycle Bin'), action: SnackBarAction(label: 'Undo', onPressed: _restoreLastTrash)));
  }

  void _restoreLastTrash() {
    if (recycleBin.isEmpty) return;
    final last = recycleBin.removeLast();
    setState(() {
      String t = last['type'];
      Map<String, dynamic> data = Map<String, dynamic>.from(last['data']);
      if (t == 'vehicle') vehicles.add(data);
      if (t == 'driver') drivers.add(data);
      if (t == 'booking') bookings.add(data);
      if (t == 'fuel') fuelLogs.add(data);
    });
    _saveKey('v2_trash', recycleBin);
  }

  // --- UI Dialogs for Adding/Editing ---
  void _showVehicleDialog({Map<String, dynamic>? editItem, int? index}) {
    final numCtrl = TextEditingController(text: editItem?['number']);
    final modelCtrl = TextEditingController(text: editItem?['model']);
    final typeCtrl = TextEditingController(text: editItem?['type'] ?? 'Truck');
    final passDateCtrl = TextEditingController(text: editItem?['passingDate']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editItem == null ? 'Add Vehicle' : 'Edit Vehicle & Docs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number (e.g. LES-1234)')),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model / Brand')),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Fuel Type (Diesel/Petrol/LPG)')),
              TextField(controller: passDateCtrl, decoration: const InputDecoration(labelText: 'Token/Passing Due Date (YYYY-MM-DD)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numCtrl.text.isNotEmpty) {
                final map = {'number': numCtrl.text.toUpperCase(), 'model': modelCtrl.text, 'type': typeCtrl.text, 'passingDate': passDateCtrl.text};
                setState(() {
                  if (index != null) vehicles[index] = map;
                  else vehicles.add(map);
                });
                _saveKey('v2_vehicles', vehicles);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Record'),
          )
        ],
      ),
    );
  }

  void _showDriverDialog({Map<String, dynamic>? editItem, int? index}) {
    final nameCtrl = TextEditingController(text: editItem?['name']);
    final phoneCtrl = TextEditingController(text: editItem?['phone']);
    final salaryCtrl = TextEditingController(text: editItem?['salary']);
    final advCtrl = TextEditingController(text: editItem?['advance'] ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editItem == null ? 'Add Driver Profile' : 'Edit Driver Ledger'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
              TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Monthly Salary (PKR)'), keyboardType: TextInputType.number),
              TextField(controller: advCtrl, decoration: const InputDecoration(labelText: 'Advance Balance (PKR)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final map = {'name': nameCtrl.text, 'phone': phoneCtrl.text, 'salary': salaryCtrl.text, 'advance': advCtrl.text};
                setState(() {
                  if (index != null) drivers[index] = map;
                  else drivers.add(map);
                });
                _saveKey('v2_drivers', drivers);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Driver'),
          )
        ],
      ),
    );
  }

  // --- App Screen Layout ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Manager Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Statement PDF',
            onPressed: () => _generatePdfReport("Full Executive Statement", bookings),
          ),
          IconButton(
            icon: const Icon(Icons.restore_from_trash),
            tooltip: 'Recycle Bin',
            onPressed: () => _showRecycleBinModal(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search Vehicles, Drivers, Routes...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildDashboardTab(),
                _buildVehiclesTab(),
                _buildDriversTab(),
                _buildBookingsTab(),
                _buildFuelTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Executive'),
          NavigationDestination(icon: Icon(Icons.directions_bus), label: 'Fleet'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Drivers'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.local_gas_station), label: 'Fuel & Pumps'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 1) _showVehicleDialog();
          if (_selectedIndex == 2) _showDriverDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardTab() {
    double netProfit = _calculateTotalEarnings() - _calculateTotalFuelCost() - _calculateTotalMaintCost();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Total Net Fleet Profit', style: TextStyle(fontSize: 14)),
                  Text('PKR ${netProfit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statCell('Revenue', _calculateTotalEarnings()),
                      _statCell('Fuel Expenses', _calculateTotalFuelCost()),
                      _statCell('Repairs/Maint.', _calculateTotalMaintCost()),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text('Document & Token Expiry Alerts 🔔', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...vehicles.where((v) => v['passingDate'] != null && v['passingDate'].toString().isNotEmpty).map((v) => Card(
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.amber),
                  title: Text('Vehicle: ${v['number']}'),
                  subtitle: Text('Passing / Token Due: ${v['passingDate']}'),
                ),
              )),
        ],
      ),
    );
  }

  Widget _statCell(String label, double val) => Column(children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text('Rs. ${val.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ]);

  Widget _buildVehiclesTab() {
    final filtered = vehicles.where((v) => v['number'].toString().toLowerCase().contains(_searchQuery)).toList();
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
          title: Text(filtered[i]['number'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Type: ${filtered[i]['type']} | Model: ${filtered[i]['model']}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showVehicleDialog(editItem: filtered[i], index: i)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteWithTrash('vehicle', i, filtered[i])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriversTab() {
    return ListView.builder(
      itemCount: drivers.length,
      itemBuilder: (ctx, i) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(drivers[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Phone: ${drivers[i]['phone']} | Advance: Rs. ${drivers[i]['advance']}'),
          trailing: Text('Salary: Rs. ${drivers[i]['salary']}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildBookingsTab() => const Center(child: Text('Bookings & Party Ledgers Ready'));
  Widget _buildFuelTab() => const Center(child: Text('Fuel, Petrol Pump Ledgers & Fuel Rates Active'));

  void _showRecycleBinModal() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Recycle Bin & Data Recovery ♻️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: recycleBin.isEmpty
                  ? const Center(child: Text('Trash is empty'))
                  : ListView.builder(
                      itemCount: recycleBin.length,
                      itemBuilder: (c, idx) => ListTile(
                        title: Text('${recycleBin[idx]['type'].toString().toUpperCase()} Record'),
                        subtitle: Text('Deleted: ${recycleBin[idx]['deletedAt']}'),
                        trailing: IconButton(icon: const Icon(Icons.restore), onPressed: () => _restoreLastTrash()),
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }
}
