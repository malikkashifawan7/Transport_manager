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
    const GlobalAnalyticsAndLedgerScreen(),
    const FuelAverageCalculatorScreen(),
    const DirectoryAndNotesScreen(),
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
            Text(
                vehicle == null
                    ? 'Add Fleet Vehicle'
                    : 'Edit Fleet Vehicle',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
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
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData),
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
                        child: _buildMetricCard(
                            'ACTIVE UNITS',
                            '${_vehicles.length}',
                            Colors.blueAccent)),
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
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
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
    final data = await DatabaseHelper.instance.getRecords(widget.vehicle['id']);
    setState(() => _records = data);
  }

  double get vehicleIncome => _records.where((r) => r['type'] == 'Income').fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());
  double get vehicleExpense => _records.where((r) => r['type'] == 'Expense').fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  void _generateAndSharePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Vehicle Ledger Statement', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Vehicle: ${widget.vehicle['number']} | Driver: ${widget.vehicle['driver_name']}'),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: ['Date', 'Type', 'Category', 'Description', 'Party', 'Amount (PKR)'],
                data: _records.map((r) => [r['date'], r['type'], r['sub_category'], r['title'], r['party_name'] ?? '-', r['amount'].toString()]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Income: PKR $vehicleIncome'),
              pw.Text('Total Expense: PKR $vehicleExpense'),
              pw.Text('Net Balance: PKR ${vehicleIncome - vehicleExpense}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Ledger_${widget.vehicle['number']}.pdf');
  }

  void _addTransactionDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final partyCtrl = TextEditingController();
    String type = 'Income';
    String subCategory = 'Freight Payment';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Entry for ${widget.vehicle['number']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Income')),
                      selected: type == 'Income',
                      selectedColor: Colors.green.shade100,
                      onSelected: (val) => setModalState(() {
                        type = 'Income';
                        subCategory = 'Freight Payment';
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
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
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: (type == 'Income'
                        ? ['Freight Payment', 'Advance Freight', 'Other Income']
                        : ['Diesel', 'Maintenance', 'Driver Salary', 'Challan / Toll', 'Other Expense'])
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setModalState(() => subCategory = val!),
              ),
              const SizedBox(height: 10),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Description / Route', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (PKR)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: partyCtrl, decoration: const InputDecoration(labelText: 'Party / Client Name', border: OutlineInputBorder())),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (amountCtrl.text.isNotEmpty) {
                      await DatabaseHelper.instance.addRecord({
                        'vehicle_id': widget.vehicle['id'],
                        'type': type,
                        'sub_category': subCategory,
                        'title': titleCtrl.text.isEmpty ? subCategory : titleCtrl.text,
                        'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                        'party_name': partyCtrl.text,
                        'date': DateTime.now().toString().split(' ')[0],
                      });
                      _loadVehicleRecords();
                      if (mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('SAVE RECORD'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = vehicleIncome - vehicleExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle['number']),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print / Share PDF',
            onPressed: _generateAndSharePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Income', 'PKR ${vehicleIncome.toStringAsFixed(0)}', Colors.greenAccent),
                _buildStat('Expense', 'PKR ${vehicleExpense.toStringAsFixed(0)}', Colors.redAccent),
                _buildStat('Balance', 'PKR ${balance.toStringAsFixed(0)}', balance >= 0 ? Colors.greenAccent : Colors.redAccent),
              ],
            ),
          ),
          Expanded(
            child: _records.isEmpty
                ? const Center(child: Text('No transaction records found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final item = _records[index];
                      final isIncome = item['type'] == 'Income';
                      return Card(
                        child: ListTile(
                          leading: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? Colors.green : Colors.red),
                          title: Text(item['title'] ?? item['sub_category']),
                          subtitle: Text('${item['date']} • Party: ${item['party_name'] ?? "Direct"}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${isIncome ? "+" : "-"} PKR ${item['amount']}', style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                onPressed: () async {
                                  await DatabaseHelper.instance.deleteRecord(item['id']);
                                  _loadVehicleRecords();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: _addTransactionDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

// ---------------------------------------------------------
// 3. FUEL AVERAGE CALCULATOR
// ---------------------------------------------------------
class FuelAverageCalculatorScreen extends StatefulWidget {
  const FuelAverageCalculatorScreen({super.key});

  @override
  State<FuelAverageCalculatorScreen> createState() => _FuelAverageCalculatorScreenState();
}

class _FuelAverageCalculatorScreenState extends State<FuelAverageCalculatorScreen> {
  final _kmsCtrl = TextEditingController();
  final _litersCtrl = TextEditingController();
  final _fuelPriceCtrl = TextEditingController();

  double _avgKmPerLiter = 0.0;
  double _costPerKm = 0.0;

  void _calculate() {
    final kms = double.tryParse(_kmsCtrl.text) ?? 0.0;
    final liters = double.tryParse(_litersCtrl.text) ?? 0.0;
    final price = double.tryParse(_fuelPriceCtrl.text) ?? 0.0;

    if (kms > 0 && liters > 0) {
      setState(() {
        _avgKmPerLiter = kms / liters;
        _costPerKm = (liters * price) / kms;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Mileage Calculator'), backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _kmsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Distance Driven (KM)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _litersCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Fuel Consumed (Liters)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _fuelPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fuel Price per Liter (PKR)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                onPressed: _calculate,
                child: const Text('CALCULATE AVERAGE'),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Average Mileage: ${_avgKmPerLiter.toStringAsFixed(2)} KM / Liter', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 10),
                    Text('Fuel Cost per KM: PKR ${_costPerKm.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. GLOBAL LEDGER
// ---------------------------------------------------------
class GlobalAnalyticsAndLedgerScreen extends StatefulWidget {
  const GlobalAnalyticsAndLedgerScreen({super.key});

  @override
  State<GlobalAnalyticsAndLedgerScreen> createState() => _GlobalAnalyticsAndLedgerScreenState();
}

class _GlobalAnalyticsAndLedgerScreenState extends State<GlobalAnalyticsAndLedgerScreen> {
  List<Map<String, dynamic>> _allRecords = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() async {
    final data = await DatabaseHelper.instance.getRecords(null);
    setState(() => _allRecords = data);
  }

  double get totalFleetIncome => _allRecords.where((r) => r['type'] == 'Income').fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());
  double get totalFleetExpense => _allRecords.where((r) => r['type'] == 'Expense').fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  @override
  Widget build(BuildContext context) {
    final netProfit = totalFleetIncome - totalFleetExpense;

    return Scaffold(
      appBar: AppBar(title: const Text('Overall Fleet Ledger'), backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCard('Total Revenue', 'PKR ${totalFleetIncome.toStringAsFixed(0)}', Colors.greenAccent),
                _buildCard('Total Expense', 'PKR ${totalFleetExpense.toStringAsFixed(0)}', Colors.redAccent),
                _buildCard('Net Profit/Loss', 'PKR ${netProfit.toStringAsFixed(0)}', netProfit >= 0 ? Colors.greenAccent : Colors.redAccent),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _allRecords.length,
              itemBuilder: (context, index) {
                final item = _allRecords[index];
                final isIncome = item['type'] == 'Income';
                return Card(
                  child: ListTile(
                    title: Text(item['title'] ?? item['sub_category']),
                    subtitle: Text('${item['date']} • Party: ${item['party_name'] ?? "Direct"}'),
                    trailing: Text(
                      '${isIncome ? "+" : "-"} PKR ${item['amount']}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

// ---------------------------------------------------------
// 5. NOTEPAD & REMINDERS (FIXED)
// ---------------------------------------------------------
class DirectoryAndNotesScreen extends StatefulWidget {
  const DirectoryAndNotesScreen({super.key});

  @override
  State<DirectoryAndNotesScreen> createState() => _DirectoryAndNotesScreenState();
}

class _DirectoryAndNotesScreenState extends State<DirectoryAndNotesScreen> {
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() async {
    final data = await DatabaseHelper.instance.getNotes();
    setState(() => _notes = data);
  }

  void _addNoteDialog({Map<String, dynamic>? note}) {
    final titleCtrl = TextEditingController(text: note?['title'] ?? '');
    final contentCtrl = TextEditingController(text: note?['content'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(note == null ? 'Add Note / Memo' : 'Edit Note', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Details', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'title': titleCtrl.text,
                  'content': contentCtrl.text,
                  'date': DateTime.now().toString().split(' ')[0],
                };
                if (note == null) {
                  await DatabaseHelper.instance.addNote(data);
                } else {
                  await DatabaseHelper.instance.updateNote(note['id'], data);
                }
                _loadNotes();
                if (mounted) Navigator.pop(ctx);
              },
              child: Text(note == null ? 'SAVE NOTE' : 'UPDATE NOTE'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notepad & Reminders'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final n = _notes[index];
          return Card(
            child: ListTile(
              title: Text(n['title'] ?? 'Note'),
              subtitle: Text(n['content'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _addNoteDialog(note: n),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await DatabaseHelper.instance.deleteNote(n['id']);
                      _loadNotes();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: () => _addNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notepad & Reminders'), backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final n = _notes[index];
          return Card(
            child: ListTile(
              title: Text(n['title'] ?? 'Note'),
              subtitle: Text(n['content'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _addNoteDialog(note: n)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline
