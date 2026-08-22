import 'package:flutter/material.dart';

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

class Vehicle {
  final String number;
  final String model;
  final String driver;

  Vehicle({required this.number, required this.model, required this.driver});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final List<Vehicle> vehicles = [];

  void _addVehicle(String number, String model, String driver) {
    setState(() {
      vehicles.add(Vehicle(number: number, model: model, driver: driver));
    });
  }

  void _showAddVehicleDialog() {
    final numberController = TextEditingController();
    final modelController = TextEditingController();
    final driverController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numberController, decoration: const InputDecoration(labelText: 'Vehicle Number (e.g. LES-1234)')),
            TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Model / Type')),
            TextField(controller: driverController, decoration: const InputDecoration(labelText: 'Assigned Driver')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numberController.text.isNotEmpty) {
                _addVehicle(numberController.text, modelController.text, driverController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save Vehicle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Manager Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_active), onPressed: () {}),
        ],
      ),
      body: _selectedIndex == 0 ? buildDashboard() : buildVehiclesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.directions_bus), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Reports'),
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
                  StatItem(title: 'Total Fleet', value: '${vehicles.length}'),
                  const StatItem(title: 'Active Trips', value: '5'),
                  const StatItem(title: 'Pending Bal', value: 'Rs. 45k'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Main Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.directions_bus, color: Colors.indigo),
            title: const Text('Manage Fleet / Vehicles'),
            subtitle: Text('${vehicles.length} vehicles registered'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _selectedIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget buildVehiclesList() {
    if (vehicles.isEmpty) {
      return const Center(child: Text('No vehicles added yet. Tap + to add one!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final item = vehicles[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
            title: Text(item.number, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Model: ${item.model} | Driver: ${item.driver}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() => vehicles.removeAt(index));
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
