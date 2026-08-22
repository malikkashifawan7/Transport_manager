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

  void _showAddVehicleDialog() {
    final numCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final driverCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number (e.g. LES-3514)')),
            TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model / Type')),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Assigned Driver')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numCtrl.text.isNotEmpty) {
                setState(() {
                  vehicles.add({'number': numCtrl.text.toUpperCase(), 'model': modelCtrl.text, 'driver': driverCtrl.text});
                });
                _saveData('vehicles', vehicles);
                Navigator.pop(context);
              }
            },
            child: const Text('Save Vehicle'),
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
        title: const Text('Add Fuel Log'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: vehCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: litCtrl, decoration: const InputDecoration(labelText: 'Liters'), keyboardType: TextInputType.number),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Total Cost (PKR)'), keyboardType: TextInputType.number),
            TextField(controller: pumpCtrl, decoration: const InputDecoration(labelText: 'Pump / Vendor')),
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
            child: const Text('Save Log'),
          ),
        ],
      ),
    );
  }

  void _showAddBookingDialog([String? defaultVehicle]) {
    final custCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final vehCtrl = TextEditingController(text: defaultVehicle ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Booking / Tour'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: vehCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: custCtrl, decoration: const InputDecoration(labelText: 'Customer / Party')),
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route / Journey')),
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount (PKR)'), keyboardType: TextInputType.number),
          ],
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
                  subtitle: Text('Driver: ${v['driver']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openVehicleDetail(v),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildVehiclesList() {
    if (vehicles.isEmpty) {
      return const Center(child: Text('No Vehicles added yet. Tap + to add!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final item = vehicles[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
            title: Text(item['number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Model: ${item['model']} | Driver: ${item['driver']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() => vehicles.removeAt(index));
                _saveData('vehicles', vehicles);
              },
            ),
            onTap: () => _openVehicleDetail(item),
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
            title: Text(b['customer'] ?? ''),
            subtitle: Text('Vehicle: ${b['vehicle']} | Route: ${b['route']}'),
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

  void _openVehicleDetail(Map<String, String> vehicle) {
    final String vNum = vehicle['number'] ?? '';
    final vFuel = fuelLogs.where((f) => f['vehicle'] == vNum).toList();
    final vBookings = bookings.where((b) => b['vehicle'] == vNum).toList();

    double totalFuel = 0;
    for (var f in vFuel) {
      totalFuel += double.tryParse(f['cost'] ?? '0') ?? 0;
    }

    double totalEarnings = 0;
    for (var b in vBookings) {
      totalEarnings += double.tryParse(b['amount'] ?? '0') ?? 0;
    }

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
                            Text('Driver: ${vehicle['driver']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Model: ${vehicle['model']}'),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            StatItem(title: 'Earnings', value: 'Rs. ${totalEarnings.toStringAsFixed(0)}'),
                            StatItem(title: 'Fuel Cost', value: 'Rs. ${totalFuel.toStringAsFixed(0)}'),
                            StatItem(title: 'Profit', value: 'Rs. ${(totalEarnings - totalFuel).toStringAsFixed(0)}'),
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
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Fuel Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                vFuel.isEmpty
                    ? const Padding(padding: EdgeInsets.all(8.0), child: Text('No fuel logs for this vehicle.'))
                    : Column(
                        children: vFuel
                            .map((f) => ListTile(
                                  title: Text('Rs. ${f['cost']} (${f['liters']} Liters)'),
                                  subtitle: Text('Pump: ${f['pump']}'),
                                ))
                            .toList(),
                      ),
                const SizedBox(height: 10),
                const Text('Bookings & Trips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                vBookings.isEmpty
                    ? const Padding(padding: EdgeInsets.all(8.0), child: Text('No bookings for this vehicle.'))
                    : Column(
                        children: vBookings
                            .map((b) => ListTile(
                                  title: Text('${b['customer']} (${b['route']})'),
                                  subtitle: Text('Rs. ${b['amount']}'),
                                ))
                            .toList(),
                      ),
              ],
            ),
          ),
        ),
      ),
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
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo)),
        Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
      ],
    );
  }
}
