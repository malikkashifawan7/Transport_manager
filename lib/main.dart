import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportERPApp());
}

class TransportERPApp extends StatelessWidget {
  const TransportERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Hisab ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFF2563EB),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

      final List<Widget> _screens = [
    const FleetDashboardScreen(),
    const Center(child: Text('Analytics & Ledger')),
    const Center(child: Text('Fuel Calculator')),
    const Center(child: Text('Directory & Notes')),
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.directions_bus_rounded), label: 'Fleet Hub'),
          NavigationDestination(
              icon: Icon(Icons.analytics_rounded), label: 'Total Ledger'),
          NavigationDestination(
              icon: Icon(Icons.calculate_rounded), label: 'Avg Calculator'),
          NavigationDestination(
              icon: Icon(Icons.folder_shared_rounded), label: 'Notepad'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 1. FLEET DASHBOARD SCREEN
// ---------------------------------------------------------
class FleetDashboardScreen extends StatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  State<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends State<FleetDashboardScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _allRecords = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    final vData = await DatabaseHelper.instance.getVehicles();
    final rData = await DatabaseHelper.instance.getRecords(null);
    setState(() {
      _vehicles = vData;
      _allRecords = rData;
    });
  }

  double get totalIncome => _allRecords
      .where((r) => r['type'] == 'Income')
      .fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  double get totalExpense => _allRecords
      .where((r) => r['type'] == 'Expense')
      .fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  List<Map<String, dynamic>> get _filteredVehicles {
    if (_searchQuery.isEmpty) return _vehicles;
    return _vehicles.where((v) {
      final num = (v['number'] ?? '').toString().toLowerCase();
      final driver = (v['driver_name'] ?? '').toString().toLowerCase();
      return num.contains(_searchQuery.toLowerCase()) ||
          driver.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openVehicleDialog({Map<String, dynamic>? vehicle}) {
    final numCtrl = TextEditingController(text: vehicle?['number'] ?? '');
    final driverCtrl =
        TextEditingController(text: vehicle?['driver_name'] ?? '');
    final phoneCtrl =
        TextEditingController(text: vehicle?['driver_phone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vehicle == null ? 'Add Fleet Vehicle' : 'Edit Fleet Vehicle',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
                controller: numCtrl,
                decoration: const InputDecoration(
                    labelText: 'Reg Number (e.g. LES-786)',
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: driverCtrl,
                decoration: const InputDecoration(
                    labelText: 'Driver Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white),
                onPressed: () async {
                  if (numCtrl.text.isNotEmpty) {
                    final data = {
                      'number': numCtrl.text,
                      'driver_name': driverCtrl.text,
                      'driver_phone': phoneCtrl.text,
                      'type': 'Truck / Trailer',
                    };
                    if (vehicle == null) {
                      await DatabaseHelper.instance.addVehicle(data);
                    } else {
                      await DatabaseHelper.instance
                          .updateVehicle(vehicle['id'], data);
                    }
                    _loadDashboardData();
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child:
                    Text(vehicle == null ? 'SAVE VEHICLE' : 'UPDATE VEHICLE'),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Operations Hub',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadDashboardData),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildMetricCard('ACTIVE UNITS',
                            '${_vehicles.length}', Colors.blueAccent)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildMetricCard(
                            'TOTAL REVENUE',
                            'PKR ${totalIncome.toStringAsFixed(0)}',
                            Colors.greenAccent)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildMetricCard(
                            'NET PROFIT',
                            'PKR ${netProfit.toStringAsFixed(0)}',
                            netProfit >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search Vehicle No or Driver...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white12,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredVehicles.length,
              itemBuilder: (context, index) {
                final v = _filteredVehicles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.local_shipping_rounded,
                          color: Color(0xFF0F172A), size: 28),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(v['number'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('ACTIVE',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                          'Driver: ${v['driver_name']} | Contact: ${v['driver_phone']}'),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blueAccent),
                          onPressed: () => _openVehicleDialog(vehicle: v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () async {
                            await DatabaseHelper.instance
                                .deleteVehicle(v['id']);
                            _loadDashboardData();
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => VehicleDetailsScreen(vehicle: v)),
                      ).then((_) => _loadDashboardData());
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: () => _openVehicleDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. VEHICLE DETAILS WITH PDF PRINTING
// ---------------------------------------------------------
class VehicleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadVehicleRecords();
  }

  void _loadVehicleRecords() async {
    final data =
        await DatabaseHelper.instance.getRecords(widget.vehicle['id']);
    setState(() => _records = data);
  }

  double get vehicleIncome => _records
      .where((r) => r['type'] == 'Income')
      .fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  double get vehicleExpense => _records
      .where((r) => r['type'] == 'Expense')
      .fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  void _generateAndSharePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Vehicle Ledger Statement',
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Vehicle: ${widget.vehicle['number']} | Driver: ${widget.vehicle['driver_name']}'),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: [
                  'Date',
                  'Type',
                  'Category',
                  'Description',
                  'Party',
                  'Amount (PKR)'
                ],
                data: _records
                    .map((r) => [
                          r['date'],
                          r['type'],
                          r['sub_category'],
                          r['title'],
                          r['party_name'] ?? '-',
                          r['amount'].toString()
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Income: PKR $vehicleIncome'),
              pw.Text('Total Expense: PKR $vehicleExpense'),
              pw.Text('Net Balance: PKR ${vehicleIncome - vehicleExpense}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Ledger_${widget.vehicle['number']}.pdf');
  }

  void _addTransactionDialog() {
  String type = 'Expense';
  String subCategory = 'Diesel';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Transaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Center(child: Text('Income')),
                    selected: type == 'Income',
                    selectedColor: Colors.green.shade100,
                    onSelected: (val) => setModalState(() {
                      type = 'Income';
                      subCategory = 'Freight Payment';
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Center(child: Text('Expense')),
                    selected: type == 'Expense',
                    selectedColor: Colors.red.shade100,
                    onSelected: (val) => setModalState(() {
                      type = 'Expense';
                      subCategory = 'Diesel';
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: subCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: (type == 'Income'
                      ? ['Freight Payment', 'Advance Freight', 'Other Income']
                      : [
                          'Diesel',
                          'Maintenance',
                          'Driver Salary',
                          'Challan / Toll',
                          'Other Expense'
                        ])
                  .map((cat) => DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
                            onChanged: (val) {
                if (val != null) {
                  setModalState(() {
                    subCategory = val;
                  });
                        }
      },
    ), // Line 548: DropdownButtonFormField close
  ],   // Line 549: Column children close
),     // Line 550: Column close
),     // Line 551: Padding close
),     // Line 552: StatefulBuilder close
);     // Line 553: showModalBottomSheet close
}      // Line 554: _addTransactionDialog function close


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Details')),
      body: const Center(child: Text('Vehicle Details Screen')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

