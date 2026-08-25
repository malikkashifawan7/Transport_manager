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
    const TotalLedgerScreen(),
    const ServicesAndKhataScreen(),
    FuelAverageCalculatorScreen(),
    const DirectoryNotesScreen(),
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
            icon: Icon(Icons.directions_bus_rounded),
            label: 'Fleet Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_rounded),
            label: 'Total Ledger',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_rounded),
            label: 'Khata & Service',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_rounded),
            label: 'Avg Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_shared_rounded),
            label: 'Notepad',
          ),
        ],
      ),
    );
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
class FuelAverageCalculatorScreen extends StatefulWidget {
  const FuelAverageCalculatorScreen({super.key});

  @override
  State<FuelAverageCalculatorScreen> createState() => _FuelAverageCalculatorScreenState();
}

class _FuelAverageCalculatorScreenState extends State<FuelAverageCalculatorScreen> {
  final _distController = TextEditingController();
  final _fuelController = TextEditingController();
  final _priceController = TextEditingController();

  double? _average;
  double? _totalCost;
  double? _costPerKm;

  void _calculate() {
    final dist = double.tryParse(_distController.text) ?? 0;
    final fuel = double.tryParse(_fuelController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (dist > 0 && fuel > 0) {
      setState(() {
        _average = dist / fuel;
        _totalCost = fuel * price;
        _costPerKm = price > 0 ? (fuel * price) / dist : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Average Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _distController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Distance (KM)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.add_location_alt_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fuelController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fuel Consumed (Liters)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fuel Price per Liter (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate Average'),
              ),
            ),
            if (_average != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                                      children: [
                    Text(
                      '${_average!.toStringAsFixed(2)} KM/L',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_totalCost != null && _totalCost! > 0) ...[
                      Text('Total Trip Fuel Cost: Rs ${_totalCost!.toStringAsFixed(0)}'),
                      Text('Cost Per KM: Rs ${_costPerKm!.toStringAsFixed(2)}/KM'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}
class TotalLedgerScreen extends StatelessWidget {
  const TotalLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Total Ledger & Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Total Income', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Rs 0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: Colors.red.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Total Expense', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Rs 0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Net Profit / Loss:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Rs 0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class DirectoryNotesScreen extends StatefulWidget {
  const DirectoryNotesScreen({super.key});

  @override
  State<DirectoryNotesScreen> createState() => _DirectoryNotesScreenState();
}

class _DirectoryNotesScreenState extends State<DirectoryNotesScreen> {
  final List<Map<String, String>> _notes = [];
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  void _addNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact / Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title / Driver Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Phone / Details', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty) {
                setState(() {
                  _notes.add({
                    'title': _titleController.text,
                    'content': _contentController.text,
                  });
                });
                _titleController.clear();
                _contentController.clear();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Directory & Notes')),
      body: _notes.isEmpty
          ? const Center(child: Text('No contacts or notes added yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.note_alt_outlined),
                    title: Text(_notes[index]['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_notes[index]['content'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _notes.removeAt(index)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
class ServicesAndKhataScreen extends StatefulWidget {
  const ServicesAndKhataScreen({super.key});

  @override
  State<ServicesAndKhataScreen> createState() => _ServicesAndKhataScreenState();
}

class _ServicesAndKhataScreenState extends State<ServicesAndKhataScreen> {
  final List<Map<String, String>> _khataEntries = [];
  final List<Map<String, String>> _maintenanceLogs = [];

  // Controllers for Khata
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  String _transactionType = 'Udhar (Gave)'; // or 'Jama (Received)'

  // Controllers for Maintenance
  final _vehicleController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _costController = TextEditingController();

  void _addKhataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Udhar Khata Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _personController,
              decoration: const InputDecoration(labelText: 'Person / Vendor Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (Rs)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _transactionType,
              items: ['Udhar (Gave)', 'Jama (Received)']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _transactionType = val!),
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_personController.text.isNotEmpty && _amountController.text.isNotEmpty) {
                setState(() {
                  _khataEntries.add({
                    'person': _personController.text,
                    'amount': _amountController.text,
                    'type': _transactionType,
                    'date': DateTime.now().toString().split(' ')[0],
                  });
                });
                _personController.clear();
                _amountController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Maintenance / Oil Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _vehicleController,
              decoration: const InputDecoration(labelText: 'Vehicle No / Model', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _serviceTypeController,
              decoration: const InputDecoration(labelText: 'Work Done (e.g. Oil Change, Tuning)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cost (Rs)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_vehicleController.text.isNotEmpty) {
                setState(() {
                  _maintenanceLogs.add({
                    'vehicle': _vehicleController.text,
                    'service': _serviceTypeController.text,
                    'cost': _costController.text,
                    'date': DateTime.now().toString().split(' ')[0],
                  });
                });
                _vehicleController.clear();
                _serviceTypeController.clear();
                _costController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Save Log'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Services & Khata'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.menu_book), text: 'Udhar Khata'),
              Tab(icon: Icon(Icons.build), text: 'Maintenance'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Udhar Khata
            Scaffold(
              body: _khataEntries.isEmpty
                  ? const Center(child: Text('No Khata records added yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _khataEntries.length,
                      itemBuilder: (context, index) {
                        final item = _khataEntries[index];
                        final isUdhar = item['type'] == 'Udhar (Gave)';
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              isUdhar ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isUdhar ? Colors.red : Colors.green,
                            ),
                            title: Text(item['person'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item['type']} • ${item['date']}'),
                            trailing: Text(
                              'Rs ${item['amount']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isUdhar ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _addKhataDialog,
                label: const Text('Add Khata'),
                icon: const Icon(Icons.add),
              ),
            ),
            // Tab 2: Maintenance & Oil Change
            Scaffold(
              body: _maintenanceLogs.isEmpty
                  ? const Center(child: Text('No maintenance logs added yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _maintenanceLogs.length,
                      itemBuilder: (context, index) {
                        final item = _maintenanceLogs[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.oil_barrel_outlined, color: Colors.orange),
                            title: Text('${item['vehicle']} - ${item['service']}'),
                            subtitle: Text('Date: ${item['date']}'),
                            trailing: Text(
                              'Rs ${item['cost']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        );
                      },
                    ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _addMaintenanceDialog,
                label: const Text('Log Service'),
                icon: const Icon(Icons.build_circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
