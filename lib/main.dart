import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MaterialApp(home: DashboardScreen(), debugShowCheckedModeBanner: false));

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<Map<String, String>> vehicles = [], bookings = [], fuelLogs = [], maintenanceLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vehicles = List<Map<String, String>>.from(json.decode(prefs.getString('vehicles') ?? '[]').map((e) => Map<String, String>.from(e)));
      bookings = List<Map<String, String>>.from(json.decode(prefs.getString('bookings') ?? '[]').map((e) => Map<String, String>.from(e)));
      fuelLogs = List<Map<String, String>>.from(json.decode(prefs.getString('fuelLogs') ?? '[]').map((e) => Map<String, String>.from(e)));
      maintenanceLogs = List<Map<String, String>>.from(json.decode(prefs.getString('maintenanceLogs') ?? '[]').map((e) => Map<String, String>.from(e)));
    });
  }

  Future<void> _saveData(String key, List<Map<String, String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  void _showAddVehicleDialog({Map<String, String>? editVehicle, int? editIndex}) {
    final numCtrl = TextEditingController(text: editVehicle?['number'] ?? '');
    final modelCtrl = TextEditingController(text: editVehicle?['model'] ?? '');
    final driverCtrl = TextEditingController(text: editVehicle?['driver'] ?? '');
    final phoneCtrl = TextEditingController(text: editVehicle?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editVehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model')),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numCtrl.text.isNotEmpty) {
                setState(() {
                  final data = {'number': numCtrl.text.toUpperCase(), 'model': modelCtrl.text, 'driver': driverCtrl.text, 'phone': phoneCtrl.text};
                  if (editIndex != null) vehicles[editIndex] = data;
                  else vehicles.add(data);
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Fuel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: vehCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: litCtrl, decoration: const InputDecoration(labelText: 'Liters'), keyboardType: TextInputType.number),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Total Cost (PKR)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (vehCtrl.text.isNotEmpty && costCtrl.text.isNotEmpty) {
                setState(() {
                  fuelLogs.add({'vehicle': vehCtrl.text.toUpperCase(), 'liters': litCtrl.text, 'cost': costCtrl.text, 'date': DateTime.now().toString().split(' ')[0]});
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
        title: const Text('Add Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: vehCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: custCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route')),
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount (PKR)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (custCtrl.text.isNotEmpty) {
                setState(() {
                  bookings.add({'vehicle': vehCtrl.text.toUpperCase(), 'customer': custCtrl.text, 'route': routeCtrl.text, 'amount': amtCtrl.text, 'date': DateTime.now().toString().split(' ')[0]});
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
    return Scaffold(
      appBar: AppBar(title: const Text('Transport Manager Pro')),
      body: _selectedIndex == 0
          ? ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: Text(v['number'] ?? ''),
                  subtitle: Text('Driver: ${v['driver']}'),
                  onTap: () => _openVehicleDetail(v, index),
                );
              },
            )
          : const Center(child: Text('Tab View')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVehicleDialog(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Fleet'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.local_gas_station), label: 'Fuel'),
        ],
      ),
    );
  }

  void _openVehicleDetail(Map<String, String> vehicle, int vIndex) {
    final String vNum = vehicle['number'] ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Account: $vNum')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Driver: ${vehicle['driver']} | Phone: ${vehicle['phone']}'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: () => _showAddFuelDialog(vNum), child: const Text('Add Fuel')),
                    ElevatedButton(onPressed: () => _showAddBookingDialog(vNum), child: const Text('Add Booking')),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
