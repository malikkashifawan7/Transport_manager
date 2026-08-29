import 'package:flutter/material.dart';
import '../database_helper.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({Key? key}) : super(key: key);

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _fuelLogs = [];
  List<Map<String, dynamic>> _maintenanceLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final vehicles = await DatabaseHelper.instance.fetchAll('vehicles');
    final fuels = await DatabaseHelper.instance.fetchAll('fuel_logs');
    final maintenance = await DatabaseHelper.instance.fetchAll('maintenance_logs');

    setState(() {
      _vehicles = vehicles;
      _fuelLogs = fuels;
      _maintenanceLogs = maintenance;
      _isLoading = false;
    });
  }

  void _showAddFuelDialog() {
    final vehicleController = TextEditingController(
      text: _vehicles.isNotEmpty ? _vehicles.first['number']?.toString() : '',
    );
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final rateController = TextEditingController();
    final litersController = TextEditingController();
    final odometerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Fuel Record', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_vehicles.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Vehicle'),
                  value: _vehicles.first['number']?.toString(),
                  items: _vehicles.map((v) {
                    final num = v['number']?.toString() ?? '';
                    return DropdownMenuItem(value: num, child: Text(num));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) vehicleController.text = val;
                  },
                ),
              TextField(
                controller: vehicleController,
                decoration: const InputDecoration(labelText: 'Vehicle Number (Type or Select)'),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              ),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Rate per Liter'),
              ),
              TextField(
                controller: litersController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Liters Filled'),
              ),
              TextField(
                controller: odometerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Odometer (KM)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final vehNum = vehicleController.text.trim();
              if (vehNum.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter or select a vehicle number')),
                );
                return;
              }

              final rate = double.tryParse(rateController.text.trim()) ?? 0.0;
              final liters = double.tryParse(litersController.text.trim()) ?? 0.0;
              final total = rate * liters;

              await DatabaseHelper.instance.insertRecord('fuel_logs', {
                'vehicle_number': vehNum,
                'date': dateController.text.trim(),
                'rate': rate,
                'liters': liters,
                'total_cost': total,
                'odometer': double.tryParse(odometerController.text.trim()) ?? 0.0,
              });

              if (mounted) {
                Navigator.pop(context);
                _loadAllData();
              }
            },
            child: const Text('Save Record'),
          ),
        ],
      ),
    );
  }

  void _showAddMaintenanceDialog() {
    final vehicleController = TextEditingController(
      text: _vehicles.isNotEmpty ? _vehicles.first['number']?.toString() : '',
    );
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final workController = TextEditingController();
    final costController = TextEditingController();
    final mechanicController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Maintenance Record', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_vehicles.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Vehicle'),
                  value: _vehicles.first['number']?.toString(),
                  items: _vehicles.map((v) {
                    final num = v['number']?.toString() ?? '';
                    return DropdownMenuItem(value: num, child: Text(num));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) vehicleController.text = val;
                  },
                ),
              TextField(
                controller: vehicleController,
                decoration: const InputDecoration(labelText: 'Vehicle Number (Type or Select)'),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              ),
              TextField(
                controller: workController,
                decoration: const InputDecoration(labelText: 'Work Description (e.g. Oil Change)'),
              ),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Cost'),
              ),
              TextField(
                controller: mechanicController,
                decoration: const InputDecoration(labelText: 'Mechanic / Shop Name'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final vehNum = vehicleController.text.trim();
              if (vehNum.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter or select a vehicle number')),
                );
                return;
              }

              await DatabaseHelper.instance.insertRecord('maintenance_logs', {
                'vehicle_number': vehNum,
                'date': dateController.text.trim(),
                'work_description': workController.text.trim().isEmpty ? 'General Service' : workController.text.trim(),
                'cost': double.tryParse(costController.text.trim()) ?? 0.0,
                'mechanic_name': mechanicController.text.trim(),
              });

              if (mounted) {
                Navigator.pop(context);
                _loadAllData();
              }
            },
            child: const Text('Save Record'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel & Maintenance Merged', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.local_gas_station, color: Colors.white), text: 'Fuel Fillings'),
            Tab(icon: Icon(Icons.build, color: Colors.white), text: 'Maintenance'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _fuelLogs.isEmpty
                    ? const Center(child: Text('No fuel logs saved yet.'))
                    : ListView.builder(
                        itemCount: _fuelLogs.length,
                        itemBuilder: (context, index) {
                          final item = _fuelLogs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child: Icon(Icons.local_gas_station, color: Colors.white),
                              ),
                              title: Text('Vehicle: ${item['vehicle_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Date: ${item['date']} | Rate: Rs.${item['rate']}/L | ${item['liters']} Liters'),
                              trailing: Text('Rs. ${item['total_cost']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                            ),
                          );
                        },
                      ),
                _maintenanceLogs.isEmpty
                    ? const Center(child: Text('No maintenance logs saved yet.'))
                    : ListView.builder(
                        itemCount: _maintenanceLogs.length,
                        itemBuilder: (context, index) {
                          final item = _maintenanceLogs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.build, color: Colors.white),
                              ),
                              title: Text('Vehicle: ${item['vehicle_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Work: ${item['work_description']}\nDate: ${item['date']} (${item['mechanic_name'] ?? 'N/A'})'),
                              trailing: Text('Rs. ${item['cost']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
                            ),
                          );
                        },
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddFuelDialog();
          } else {
            _showAddMaintenanceDialog();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
