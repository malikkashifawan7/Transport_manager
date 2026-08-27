import 'package:flutter/material.dart';
import 'database_helper.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  void _loadDrivers() async {
    final data = await DatabaseHelper.instance.fetchAll('vehicles');
    setState(() {
      _vehicles = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers List & Details'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _vehicles.isEmpty
          ? const Center(child: Text('Vehicles screen se drivers aur gari add karein.'))
          : ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final v = _vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1A237E),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(v['driverName'] ?? 'No Driver Assigned', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Mobile: ${v['driverPhone'] ?? 'N/A'}\nAssigned Vehicle: ${v['vehicleNumber']}'),
                  ),
                );
              },
            ),
    );
  }
}
