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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load saved local data on app start
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vehicles = List<Map<String, String>>.from(
          json.decode(prefs.getString('vehicles') ?? '[]').map((e) => Map<String, String>.from(e)));
      drivers = List<Map<String, String>>.from(
          json.decode(prefs.getString('drivers') ?? '[]').map((e) => Map<String, String>.from(e)));
      bookings = List<Map<String, String>>.from(
          json.decode(prefs.getString('bookings') ?? '[]').map((e) => Map<String, String>.from(e)));
    });
  }

  // Save data locally
  Future<void> _saveData(String key, List<Map<String, String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  void _addVehicle(String number, String model, String driver) {
    setState(() {
      vehicles.add({'number': number, 'model': model, 'driver': driver});
    });
    _saveData('vehicles', vehicles);
  }

  void _addDriver(String name, String phone, String salary) {
    setState(() {
      drivers.add({'name': name, 'phone': phone, 'salary': salary});
    });
    _saveData('drivers', drivers);
  }

  void _addBooking(String customer, String route, String amount) {
    setState(() {
      bookings.add({'customer': customer, 'route': route, 'amount': amount});
    });
    _saveData('bookings', bookings);
  }

  void _showAddDialog() {
    if (_selectedIndex == 1) {
      _showVehicleDialog();
    } else if (_selectedIndex == 2) {
      _showBookingDialog();
    } else {
      _showDriverDialog();
    }
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
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numCtrl.text.isNotEmpty) {
                _addVehicle(numCtrl.text, modelCtrl.text, driverCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
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
            TextField(controller: salCtrl, decoration: const InputDecoration(labelText: 'Salary')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                _addDriver(nameCtrl.text, phoneCtrl.text, salCtrl.text);
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
            TextField(controller: custCtrl, decoration: const InputDecoration(labelText: 'Customer/Party')),
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route/Journey')),
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Booking Amount')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (custCtrl.text.isNotEmpty) {
                _addBooking(custCtrl.text, routeCtrl.text, amtCtrl.text);
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
      buildList('Drivers', drivers, Icons.person, 'name', 'phone', 'drivers'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Manager Pro', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.directions_bus), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
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
                  StatItem(title: 'Drivers', value: '${drivers.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quick Navigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.grey.shade100,
            leading: const Icon(Icons.directions_bus, color: Colors.blue),
            title: const Text('Manage Vehicles'),
            subtitle: Text('${vehicles.length} Saved'),
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.grey.shade100,
            leading: const Icon(Icons.luggage, color: Colors.green),
            title: const Text('Bookings & Tours'),
            subtitle: Text('${bookings.length} Saved'),
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.grey.shade100,
            leading: const Icon(Icons.person, color: Colors.orange),
            title: const Text('Drivers List'),
            subtitle: Text('${drivers.length} Saved'),
            onTap: () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
        Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
      ],
    );
  }
}
