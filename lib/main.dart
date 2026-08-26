import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'vehicle_details_screen.dart';
import 'pdf_export_service.dart';
import 'excel_export_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport Manager',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _FleetDashboardState();
}

class _FleetDashboardState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _recentTrips = [];
  bool _isLoading = true;

  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final vehiclesData = await DatabaseHelper.instance.getVehicles();
    final recordsData = await DatabaseHelper.instance.getRecords(null);

    double inc = 0;
    double exp = 0;

    for (var r in recordsData) {
      final amt = double.tryParse(r['amount']?.toString() ?? '0') ?? 0;
      if (r['type'] == 'Income') {
        inc += amt;
      } else {
        exp += amt;
      }
    }

    setState(() {
      _vehicles = vehiclesData;
      _recentTrips = recordsData.reversed.toList();
      _totalIncome = inc;
      _totalExpense = exp;
      _isLoading = false;
    });
  }

  void _showAddVehicleDialog() {
    final numberController = TextEditingController();
    final driverController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberController,
              decoration: const InputDecoration(labelText: 'Vehicle Number (e.g. LES-1234)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: driverController,
              decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Driver Phone', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (numberController.text.isNotEmpty) {
                await DatabaseHelper.instance.insertVehicle({
                  'number': numberController.text,
                  'driver_name': driverController.text,
                  'driver_phone': phoneController.text,
                  'status': 'Available',
                });
                if (mounted) Navigator.pop(ctx);
                _loadDashboardData();
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
    final netProfit = _totalIncome - _totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Enterprise Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () => ExcelExportService.exportAndShare(_recentTrips, 'Fleet_Summary'),
            tooltip: 'Export Excel',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => PdfExportService.generateAndShareInvoice('Fleet Summary Report', _recentTrips),
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL INCOME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                const SizedBox(height: 4),
                                Text('Rs. ${_totalIncome.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL EXPENSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                                const SizedBox(height: 4),
                                Text('Rs. ${_totalExpense.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.indigo.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('NET PROFIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                const SizedBox(height: 4),
                                Text('Rs. ${netProfit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Active Vehicles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _showAddVehicleDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Vehicle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _vehicles.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Center(child: Text('No active vehicles. Tap "+ Add Vehicle" to create.')),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _vehicles.length,
                          itemBuilder: (ctx, i) {
                            final v = _vehicles[i];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.indigo,
                                  child: Icon(Icons.directions_bus, color: Colors.white),
                                ),
                                title: Text(v['number'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Driver: ${v['driver_name'] ?? 'N/A'} • ${v['driver_phone'] ?? ''}'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VehicleDetailsScreen(
                                        vehicle: v,
                                        records: _recentTrips.where((r) => r['vehicle_id'] == v['id']).toList(),
                                      ),
                                    ),
                                  ).then((_) => _loadDashboardData());
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}

