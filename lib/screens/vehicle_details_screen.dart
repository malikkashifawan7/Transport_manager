import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../pdf_helper.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailsScreen({Key? key, required this.vehicle}) : super(key: key);

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _fuelLogs = [];
  List<Map<String, dynamic>> _maintenanceLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    setState(() => _isLoading = true);
    final vehicleNumber = widget.vehicle['number'] ?? '';
    final fuels = await DatabaseHelper.instance.getLogsByVehicle(vehicleNumber, 'fuel_logs');
    final maintenance = await DatabaseHelper.instance.getLogsByVehicle(vehicleNumber, 'maintenance_logs');

    setState(() {
      _fuelLogs = fuels;
      _maintenanceLogs = maintenance;
      _isLoading = false;
    });
  }

  void _addFuelDialog() {
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final rateController = TextEditingController();
    final litersController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Fuel for ${widget.vehicle['number']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
            TextField(controller: rateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rate / Liter')),
            TextField(controller: litersController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Liters')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final rate = double.tryParse(rateController.text) ?? 0.0;
              final liters = double.tryParse(litersController.text) ?? 0.0;
              await DatabaseHelper.instance.insertRecord('fuel_logs', {
                'vehicle_number': widget.vehicle['number'],
                'date': dateController.text,
                'rate': rate,
                'liters': liters,
                'total_cost': rate * liters,
              });
              if (mounted) Navigator.pop(context);
              _loadVehicleData();
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _addMaintenanceDialog() {
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final workController = TextEditingController();
    final costController = TextEditingController();
    final mechanicController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Maintenance for ${widget.vehicle['number']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date')),
              TextField(controller: workController, decoration: const InputDecoration(labelText: 'Work Description')),
              TextField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost')),
              TextField(controller: mechanicController, decoration: const InputDecoration(labelText: 'Mechanic / Shop Name')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.insertRecord('maintenance_logs', {
                'vehicle_number': widget.vehicle['number'],
                'date': dateController.text,
                'work_description': workController.text,
                'cost': double.tryParse(costController.text) ?? 0.0,
                'mechanic_name': mechanicController.text,
              });
              if (mounted) Navigator.pop(context);
              _loadVehicleData();
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final veh = widget.vehicle;
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle: ${veh['number']}'),
        backgroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              PdfHelper.generateVehicleInvoice(
                vehicleNumber: veh['number'] ?? '',
                fuelLogs: _fuelLogs,
                maintenanceLogs: _maintenanceLogs,
              );
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.local_gas_station), text: 'Fuel Logs'),
            Tab(icon: Icon(Icons.build), text: 'Maintenance'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Model: ${veh['type'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Driver: ${veh['driver_name'] ?? 'N/A'} (${veh['driver_phone'] ?? ''})'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Fuel Logs
                      _fuelLogs.isEmpty
                          ? const Center(child: Text('No fuel entries for this vehicle.'))
                          : ListView.builder(
                              itemCount: _fuelLogs.length,
                              itemBuilder: (context, i) {
                                final f = _fuelLogs[i];
                                return ListTile(
                                  title: Text('${f['date']} - Rs. ${f['total_cost']}'),
                                  subtitle: Text('Rate: ${f['rate']} | Liters: ${f['liters']} L'),
                                );
                              },
                            ),
                      // Maintenance Logs
                      _maintenanceLogs.isEmpty
                          ? const Center(child: Text('No maintenance records for this vehicle.'))
                          : ListView.builder(
                              itemCount: _maintenanceLogs.length,
                              itemBuilder: (context, i) {
                                final m = _maintenanceLogs[i];
                                return ListTile(
                                  title: Text('${m['work_description']} - Rs. ${m['cost']}'),
                                  subtitle: Text('Date: ${m['date']} | Mechanic: ${m['mechanic_name'] ?? 'N/A'}'),
                                );
                              },
                            ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: () {
          if (_tabController.index == 0) {
            _addFuelDialog();
          } else {
            _addMaintenanceDialog();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

