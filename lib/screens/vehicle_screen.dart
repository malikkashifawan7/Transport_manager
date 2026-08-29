import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'vehicle_details_screen.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({Key? key}) : super(key: key);

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshVehicles();
  }

  Future<void> _refreshVehicles() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchAll('vehicles');
    setState(() {
      _vehicles = data;
      _isLoading = false;
    });
  }

  void _showAddVehicleDialog() {
    final numberController = TextEditingController();
    final modelController = TextEditingController();
    final driverController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numberController, decoration: const InputDecoration(labelText: 'Gari Number (e.g. LES-3514)')),
              TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Vehicle Model / Type')),
              TextField(controller: driverController, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Driver Mobile Number')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final number = numberController.text.trim();
              if (number.isEmpty) return;

              await DatabaseHelper.instance.insertRecord('vehicles', {
                'number': number,
                'type': modelController.text.trim(),
                'driver_name': driverController.text.trim(),
                'driver_phone': phoneController.text.trim(),
              });

              if (mounted) Navigator.pop(context);
              _refreshVehicles();
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Fleet Management', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(child: Text('No vehicles added yet. Click + to add.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final item = _vehicles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1A237E),
                          child: Icon(Icons.directions_bus, color: Colors.white),
                        ),
                        title: Text('Gari No: ${item['number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Model: ${item['type'] ?? 'N/A'}\nDriver: ${item['driver_name'] ?? 'N/A'}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VehicleDetailsScreen(vehicle: item),
                            ),
                          ).then((_) => _refreshVehicles());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: _showAddVehicleDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

