import 'package:flutter/material.dart';
import 'dashboard.dart';

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
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class StatItem extends StatelessWidget {
  final String title;
  final String value;
  const StatItem({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 11,
          ),
        ),
      ],
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
  List<Map<String, String>> bookings = [];
  List<Map<String, String>> fuelLogs = [];
  List<Map<String, String>> maintenanceLogs = [];

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
      bookings = List<Map<String, String>>.from(
          json.decode(prefs.getString('bookings') ?? '[]').map((e) => Map<String, String>.from(e)));
      fuelLogs = List<Map<String, String>>.from(
          json.decode(prefs.getString('fuelLogs') ?? '[]').map((e) => Map<String, String>.from(e)));
      maintenanceLogs = List<Map<String, String>>.from(
          json.decode(prefs.getString('maintenanceLogs') ?? '[]').map((e) => Map<String, String>.from(e)));
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

  void _showAddVehicleDialog({Map<String, String>? editVehicle, int? editIndex}) {
    final numCtrl = TextEditingController(text: editVehicle?['number'] ?? '');
    final modelCtrl = TextEditingController(text: editVehicle?['model'] ?? '');
    final driverCtrl = TextEditingController(text: editVehicle?['driver'] ?? '');
    final phoneCtrl = TextEditingController(text: editVehicle?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editVehicle == null ? 'Add New Vehicle' : 'Edit Vehicle Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model / Type')),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Driver Contact No.'), keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numCtrl.text.isNotEmpty) {
                setState(() {
                  final data = {
                    'number': numCtrl.text.toUpperCase(),
                    'model': modelCtrl.text,
                    'driver': driverCtrl.text,
                    'phone': phoneCtrl.text,
                  };
                  if (editIndex != null) {
                    vehicles[editIndex] = data;
                  } else {
                    vehicles.add(data);
                  }
                });
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

  void _showAddFuelDialog([String? defaultVehicle]) {
    final vehCtrl = TextEditingController(text: defaultVehicle ?? '');
    final litCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final pumpCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Fuel Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: vehCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: litCtrl, decoration: const InputDecoration(labelText: 'Liters'), keyboardType: TextInputType.number),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Total Cost (PKR)'), keyboardType: TextInputType.number),
            TextField(controller: pumpCtrl, decoration: const InputDecoration(labelText: 'Pump / Station Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (vehCtrl.text.isNotEmpty && costCtrl.text.isNotEmpty) {
                setState(() {
                  fuelLogs.add({
                    'vehicle': vehCtrl.text.toUpperCase(),
                    'liters': litCtrl.text,
                    'cost': costCtrl.text,
                    'pump': pumpCtrl.text,
                    'date': DateTime.now().toString().split(' ')[0]
                  });
                });
                _saveData('fuelLogs', fuelLogs);
                Navigator.pop(context);
              }
            },
            child: const Text('Save Fuel Log'),
          ),
        ],
      ),
    );
  }

  void _showAddBookingDialog([String? defaultVehicle]) {
    final custCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final vehCtrl = TextEditingController(text: defaultVehicle ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Booking / Tour'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: vehCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
              TextField(controller: custCtrl, decoration: const InputDecoration(labelText: 'Party / Customer Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Party Phone No.'), keyboardType: TextInputType.phone),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Party Address')),
              TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route / Trip Path')),
              TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Booking Amount (PKR)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (custCtrl.text.isNotEmpty) {
                setState(() {
                  bookings.add({
                    'vehicle': vehCtrl.text.toUpperCase(),
                    'customer': custCtrl.text,
                    'phone': phoneCtrl.text,
                    'address': addressCtrl.text,
                    'route': routeCtrl.text,
                    'amount': amtCtrl.text,
                    'date': DateTime.now().toString().split(' ')[0]
                  });
                });
                _saveData('bookings', bookings);
                Navigator.pop(context);
              }
            },
            child: const Text('Save Booking'),
          ),
        ],
      ),
    );
  }

  void _showAddMaintenanceDialog([String? defaultVehicle]) {
    final vehCtrl = TextEditingController(text: defaultVehicle ?? '');
    final workCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Maintenance / Kaam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: vehCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: workCtrl, decoration: const InputDecoration(labelText: 'Work Description')),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Expense (PKR)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (workCtrl.text.isNotEmpty && costCtrl.text.isNotEmpty) {
                setState(() {
                  maintenanceLogs.add({
                    'vehicle': vehCtrl.text.toUpperCase(),
                    'work': workCtrl.text,
                    'cost': costCtrl.text,
                    'date': DateTime.now().toString().split(' ')[0]
                  });
                });
                _saveData('maintenanceLogs', maintenanceLogs);
                Navigator.pop(context);
              }
            },
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      buildDashboard(),
      buildVehiclesList(),
      buildBookingsList(),
      buildFuelList(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Manager Pro', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex != 0
          ? FloatingActionButton(
              onPressed: () {
                if (_selectedIndex == 1) _showAddVehicleDialog();
                else if (_selectedIndex == 2) _showAddBookingDialog();
                else if (_selectedIndex == 3) _showAddFuelDialog();
              },
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
                  StatItem(title: 'Fuel Costs', value: 'Rs. ${_calculateTotalFuelCost().toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Fleet Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final v = vehicles[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
                  title: Text(v['number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Driver: ${v['driver'] ?? 'N/A'} | ${v['phone'] ?? ''}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openVehicleDetail(v, index),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildVehiclesList() {
    if (vehicles.isEmpty) return const Center(child: Text('No Vehicles added yet.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final item = vehicles[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
            title: Text(item['number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Model: ${item['model']} | Driver: ${item['driver']} (${item['phone'] ?? ''})'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showAddVehicleDialog(editVehicle: item, editIndex: index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => vehicles.removeAt(index));
                    _saveData('vehicles', vehicles);
                  },
                ),
              ],
            ),
            onTap: () => _openVehicleDetail(item, index),
          ),
        );
      },
    );
  }

  Widget buildBookingsList() {
    if (bookings.isEmpty) return const Center(child: Text('No Bookings added yet.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.luggage)),
            title: Text('${b['customer']} (${b['phone'] ?? ''})'),
            subtitle: Text('Vehicle: ${b['vehicle']} | Route: ${b['route']}\nAddress: ${b['address'] ?? 'N/A'}'),
            trailing: Text('Rs. ${b['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
        );
      },
    );
  }

  Widget buildFuelList() {
    if (fuelLogs.isEmpty) return const Center(child: Text('No Fuel Logs added yet.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: fuelLogs.length,
      itemBuilder: (context, index) {
        final f = fuelLogs[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.local_gas_station, color: Colors.white)),
            title: Text('Vehicle: ${f['vehicle']}'),
            subtitle: Text('${f['liters']} L | Pump: ${f['pump']}'),
            trailing: Text('Rs. ${f['cost']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        );
      },
    );
  }

  void _openVehicleDetail(Map<String, String> vehicle, int vIndex) {
    final String vNum = vehicle['number'] ?? '';
    final vFuel = fuelLogs.where((f) => f['vehicle'] == vNum).toList();
    final vBookings = bookings.where((b) => b['vehicle'] == vNum).toList();
    final vMaint = maintenanceLogs.where((m) => m['vehicle'] == vNum).toList();

    double totalFuel = vFuel.fold(0, (sum, item) => sum + (double.tryParse(item['cost'] ?? '0') ?? 0));
    double totalEarnings = vBookings.fold(0, (sum, item) => sum + (double.tryParse(item['amount'] ?? '0') ?? 0));
    double totalMaint = vMaint.fold(0, (sum, item) => sum + (double.tryParse(item['cost'] ?? '0') ?? 0));
    double profit = totalEarnings - totalFuel - totalMaint;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Vehicle Account: $vNum')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.indigo.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Driver: ${vehicle['driver'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Phone: ${vehicle['phone'] ?? 'N/A'}'),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            StatItem(title: 'Earnings', value: 'Rs. ${totalEarnings.toStringAsFixed(0)}'),
                            StatItem(title: 'Fuel', value: 'Rs. ${totalFuel.toStringAsFixed(0)}'),
                            StatItem(title: 'Maintenance', value: 'Rs. ${totalMaint.toStringAsFixed(0)}'),
                            StatItem(title: 'Profit', value: 'Rs. ${profit.toStringAsFixed(0)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAddFuelDialog(vNum),
                      icon: const Icon(Icons.local_gas_station),
                      label: const Text('Add Fuel'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddBookingDialog(vNum),
                      icon: const Icon(Icons.luggage),
                      label: const Text('Add Booking'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddMaintenanceDialog(vNum),
                      icon
