import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const TransportManagerApp());
}

class TransportManagerApp extends StatelessWidget {
  const TransportManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<Map<String, String>> vehicles = [];
  List<Map<String, String>> drivers = [];
  List<Map<String, String>> bookings = [];
  List<Map<String, String>> fuelLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vehicles = List<Map<String, String>>.from(
          json.decode(prefs.getString('vehicles') ?? '[]').map((e) => Map<String, String>.from(e)));
      drivers = List<Map<String, String>>.from(
          json.decode(prefs.getString('drivers') ?? '[]').map((e) => Map<String, String>.from(e)));
      bookings = List<Map<String, String>>.from(
          json.decode(prefs.getString('bookings') ?? '[]').map((e) => Map<String, String>.from(e)));
      fuelLogs = List<Map<String, String>>.from(
          json.decode(prefs.getString('fuelLogs') ?? '[]').map((e) => Map<String, String>.from(e)));
    });
  }

  Future<void> _saveData(String key, List<Map<String, String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  double _calculateTotalFuelCost() {
    double total = 0;
    for (var log in fuelLogs) {
      total += double.tryParse(log['cost'] ?? '0') ?? 0;
    }
    return total;
  }

  void _generatePdfReport() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            cross: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('Transport Manager Pro - Summary Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Text('Total Vehicles: ${vehicles.length}'),
              pw.Text('Total Bookings: ${bookings.length}'),
              pw.Text('Total Fuel Expenses: Rs. ${_calculateTotalFuelCost().toStringAsFixed(0)}'),
              pw.SizedBox(height: 20),
              pw.Text('Vehicles List:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: vehicles.map((v) => "${v['number']} - ${v['model']} (${v['driver']})").join('\n')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _showAddDialog() {
    if (_selectedIndex == 1) _showVehicleDialog();
    else if (_selectedIndex == 2) _showBookingDialog();
    else if (_selectedIndex == 3) _showFuelDialog();
    else if (_selectedIndex == 4) _showDriverDialog();
  }

  void _showVehicleDialog() {
    final numCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final driverCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model')),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Assigned Driver')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numCtrl.text.isNotEmpty) {
                setState(() => vehicles.add({'number': numCtrl.text, 'model': modelCtrl.text, 'driver': driverCtrl.text}));
                _saveData('vehicles', vehicles);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFuelDialog() {
    final vehCtrl = TextEditingController();
    final litCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final pumpCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Fuel Log'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: vehCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: litCtrl, decoration: const InputDecoration(labelText: 'Liters'), keyboardType: TextInputType.number),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Total Cost (PKR)'), keyboardType: TextInputType.number),
            TextField(controller: pumpCtrl, decoration: const InputDecoration(labelText: 'Pump Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (vehCtrl.text.isNotEmpty && costCtrl.text.isNotEmpty) {
                setState(() => fuelLogs.add({
                      'vehicle': vehCtrl.text,
                      'liters': litCtrl.text,
                      'cost': costCtrl.text,
                      'pump': pumpCtrl.text
                    }));
                _saveData('fuelLogs', fuelLogs);
                Navigator.pop(context);
              }
            },
            child: const Text('Save Entry'),
          ),
        ],
      ),
    );
  }

  void _showDriverDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final salCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
            TextField(controller: salCtrl, decoration: const InputDecoration(labelText: 'Monthly Salary')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() => drivers.add({'name': nameCtrl.text, 'phone': phoneCtrl.text, 'salary': salCtrl.text}));
                _saveData('drivers', drivers);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog() {
    final custCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final amtCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tour / Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: custCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route')),
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Total Amount (PKR)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (custCtrl.text.isNotEmpty) {
                setState(() => bookings.add({'customer': custCtrl.text, 'route': routeCtrl.text, 'amount': amtCtrl.text}));
                _saveData('bookings', bookings);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      buildDashboard(),
      buildList('Vehicles', vehicles, Icons.directions_bus, 'number', 'model', 'vehicles'),
      buildList('Bookings', bookings, Icons.luggage, 'customer', 'route', 'bookings'),
      buildFuelList(),
      buildList('Drivers', drivers, Icons.person, 'name', 'phone', 'drivers'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Manager Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
            tooltip: 'Export PDF Report',
          )
        ],
      ),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex != 0
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.directions_bus), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.local_gas_station), label: 'Fuel'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Drivers'),
        ],
      ),
    );
  }

  Widget buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatItem(title: 'Vehicles', value: '${vehicles.length}'),
                  StatItem(title: 'Bookings', value: '${bookings.length}'),
                  StatItem(title: 'Fuel Expenses', value: 'Rs. ${_calculateTotalFuelCost().toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _generatePdfReport,
            icon: const Icon(Icons.print),
            label: const Text('Generate & Export PDF Report'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(45),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quick Navigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.grey.shade100,
            leading: const Icon(Icons.directions_bus, color: Colors.blue),
            title: const Text('Manage Vehicles'),
            subtitle: Text('${vehicles.length} Registered'),
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.grey.shade100,
            leading: const Icon(Icons.luggage, color: Colors.green),
            title: const Text('Bookings & Tours'),
            subtitle: Text('${bookings.length} Registered'),
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.grey.shade100,
            leading: const Icon(Icons.local_gas_station, color: Colors.red),
            title: const Text('Fuel Logs & Pumps'),
            subtitle: Text('Total: Rs. ${_calculateTotalFuelCost().toStringAsFixed(0)}'),
            onTap: () => setState(() => _selectedIndex = 3),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.grey.shade100,
            leading: const Icon(Icons.person, color: Colors.orange),
            title: const Text('Drivers List'),
            subtitle: Text('${drivers.length} Registered'),
            onTap: () => setState(() => _selectedIndex = 4),
          ),
        ],
      ),
    );
  }

  Widget buildFuelList() {
    if (fuelLogs.isEmpty) {
      return const Center(child: Text('No Fuel entries added yet. Tap + to add!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: fuelLogs.length,
      itemBuilder: (context, index) {
        final item = fuelLogs[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.local_gas_station, color: Colors.white)),
            title: Text('Vehicle: ${item['vehicle'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Qty: ${item['liters']} L | Pump: ${item['pump']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. ${item['cost']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () {
                    setState(() => fuelLogs.removeAt(index));
                    _saveData('fuelLogs', fuelLogs);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildList(String title, List<Map<String, String>> items, IconData icon, String key1, String key2, String storageKey) {
    if (items.isEmpty) {
      return Center(child: Text('No $title added yet. Tap + to add!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(icon)),
            title: Text(item[key1] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item[key2] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() => items.removeAt(index));
                _saveData(storageKey, items);
              },
            ),
          ),
        );
      },
    );
  }
}

class StatItem extends StatelessWidget {
  final String title;
  final String value;
  const StatItem({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
        Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
      ],
    );
  }
}
