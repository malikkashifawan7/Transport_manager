import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const TransportApp());
}

// ----------------------------------------------------
// DATABASE HELPER
// ----------------------------------------------------
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL,
        driver_name TEXT,
        driver_phone TEXT,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER,
        type TEXT,
        category TEXT,
        amount REAL,
        note TEXT,
        date TEXT
      )
    ''');
  }

  Future<int> insertVehicle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('vehicles', row);
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles');
  }

  Future<int> insertRecord(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('records', row);
  }

  Future<List<Map<String, dynamic>>> getRecords(int? vehicleId) async {
    final db = await instance.database;
    if (vehicleId != null) {
      return await db.query('records', where: 'vehicle_id = ?', whereArgs: [vehicleId]);
    }
    return await db.query('records');
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }
}

// ----------------------------------------------------
// MAIN APP & HOME NAVIGATION
// ----------------------------------------------------
class TransportApp extends StatelessWidget {
  const TransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport Manager',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.blue,
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
          NavigationDestination(icon: Icon(Icons.directions_bus_rounded), label: 'Fleet Hub'),
          NavigationDestination(icon: Icon(Icons.analytics_rounded), label: 'Total Ledger'),
          NavigationDestination(icon: Icon(Icons.handshake_rounded), label: 'Khata & Service'),
          NavigationDestination(icon: Icon(Icons.calculate_rounded), label: 'Avg Calculator'),
          NavigationDestination(icon: Icon(Icons.folder_shared_rounded), label: 'Notepad'),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 1. FLEET DASHBOARD SCREEN
// ----------------------------------------------------
class FleetDashboardScreen extends StatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  State<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends State<FleetDashboardScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final vData = await DatabaseHelper.instance.getVehicles();
    setState(() {
      _vehicles = vData;
      _isLoading = false;
    });
  }

  void _addVehicleDialog() {
    final numCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String type = 'Truck';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Driver Phone', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (numCtrl.text.isNotEmpty) {
                await DatabaseHelper.instance.insertVehicle({
                  'number': numCtrl.text,
                  'driver_name': driverCtrl.text,
                  'driver_phone': phoneCtrl.text,
                  'type': type,
                });
                if (mounted) Navigator.pop(ctx);
                _loadData();
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
      appBar: AppBar(title: const Text('Fleet Hub')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(child: Text('No vehicles added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _vehicles.length,
                  itemBuilder: (ctx, i) {
                    final v = _vehicles[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.directions_bus, size: 35),
                        title: Text(v['number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Driver: ${v['driver_name']} • ${v['driver_phone']}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => VehicleDetailScreen(vehicle: v)),
                          ).then((_) => _loadData());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVehicleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
// ----------------------------------------------------
// 2. VEHICLE DETAIL SCREEN (SAVING & LINKED)
// ----------------------------------------------------
class VehicleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  List<Map<String, dynamic>> _vehicleRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicleRecords();
  }

  Future<void> _loadVehicleRecords() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getRecords(widget.vehicle['id']);
    setState(() {
      _vehicleRecords = data;
      _isLoading = false;
    });
  }

  double get _totalIncome => _vehicleRecords
      .where((r) => r['type'] == 'Income')
      .fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  double get _totalExpense => _vehicleRecords
      .where((r) => r['type'] == 'Expense')
      .fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  void _showAddTransactionBottomSheet() {
    String type = 'Expense';
    String category = 'Challan / Toll';
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final categories = type == 'Income'
                ? ['Freight / Trip Fare', 'Bonus / Extra']
                : ['Challan / Toll', 'Fuel', 'Maintenance', 'Driver Allowance', 'Other Expense'];

            if (!categories.contains(category)) {
              category = categories.first;
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Income')),
                          selected: type == 'Income',
                          onSelected: (selected) {
                            if (selected) setModalState(() => type = 'Income');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Expense')),
                          selected: type == 'Expense',
                          onSelected: (selected) {
                            if (selected) setModalState(() => type = 'Expense');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (Rs)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Notes / Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text) ?? 0.0;
                        if (amt > 0) {
                          await DatabaseHelper.instance.insertRecord({
                            'vehicle_id': widget.vehicle['id'],
                            'type': type,
                            'category': category,
                            'amount': amt,
                            'note': noteController.text,
                            'date': DateTime.now().toString().split(' ')[0],
                          });
                          if (mounted) Navigator.pop(ctx);
                          _loadVehicleRecords();
                        }
                      },
                      child: const Text('Save Transaction'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Scaffold(
      appBar: AppBar(title: Text('${v['number']} Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      title: Text('Driver: ${v['driver_name'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Phone: ${v['driver_phone'] ?? 'N/A'}'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Text('Income', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                Text('Rs $_totalIncome', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                              children: [
                                const Text('Expense', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                Text('Rs $_totalExpense', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _vehicleRecords.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text('No transactions for this vehicle yet.')),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _vehicleRecords.length,
                          itemBuilder: (context, index) {
                            final r = _vehicleRecords[index];
                            final isInc = r['type'] == 'Income';
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  isInc ? Icons.add_circle : Icons.remove_circle,
                                  color: isInc ? Colors.green : Colors.red,
                                ),
                                title: Text('${r['category']} (Rs ${r['amount']})'),
                                subtitle: Text('${r['note'] ?? ''} • ${r['date']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                  onPressed: () async {
                                    await DatabaseHelper.instance.deleteRecord(r['id']);
                                    _loadVehicleRecords();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionBottomSheet,
        label: const Text('Add Entry'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
// ----------------------------------------------------
// 3. TOTAL LEDGER SCREEN
// ----------------------------------------------------
class TotalLedgerScreen extends StatefulWidget {
  const TotalLedgerScreen({super.key});

  @override
  State<TotalLedgerScreen> createState() => _TotalLedgerScreenState();
}

class _TotalLedgerScreenState extends State<TotalLedgerScreen> {
  List<Map<String, dynamic>> _allRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllRecords();
  }

  Future<void> _loadAllRecords() async {
    final data = await DatabaseHelper.instance.getRecords(null);
    setState(() {
      _allRecords = data;
      _isLoading = false;
    });
  }

  double get _totalIncome => _allRecords
      .where((r) => r['type'] == 'Income')
      .fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  double get _totalExpense => _allRecords
      .where((r) => r['type'] == 'Expense')
      .fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  @override
  Widget build(BuildContext context) {
    final netProfit = _totalIncome - _totalExpense;

    return Scaffold(
      appBar: AppBar(title: const Text('Total Ledger & Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('Total Income', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                Text('Rs $_totalIncome', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('Total Expense', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                Text('Rs $_totalExpense', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Net Profit / Loss:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'Rs $netProfit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: netProfit >= 0 ? Colors.blue : Colors.red,
                            ),
                          ),
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

// ----------------------------------------------------
// 4. SERVICES & UDHAR KHATA SCREEN
// ----------------------------------------------------
class ServicesAndKhataScreen extends StatefulWidget {
  const ServicesAndKhataScreen({super.key});

  @override
  State<ServicesAndKhataScreen> createState() => _ServicesAndKhataScreenState();
}

class _ServicesAndKhataScreenState extends State<ServicesAndKhataScreen> {
  final List<Map<String, String>> _khataEntries = [];
  final List<Map<String, String>> _maintenanceLogs = [];

  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  String _transactionType = 'Udhar (Gave)';

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
            TextField(controller: _personController, decoration: const InputDecoration(labelText: 'Person / Vendor Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _transactionType,
              items: ['Udhar (Gave)', 'Jama (Received)'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
            TextField(controller: _vehicleController, decoration: const InputDecoration(labelText: 'Vehicle No / Model', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _serviceTypeController, decoration: const InputDecoration(labelText: 'Work Done (e.g. Oil Change)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (Rs)', border: OutlineInputBorder())),
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
                            leading: Icon(isUdhar ? Icons.arrow_upward : Icons.arrow_downward, color: isUdhar ? Colors.red : Colors.green),
                            title: Text(item['person'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item['type']} • ${item['date']}'),
                            trailing: Text('Rs ${item['amount']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isUdhar ? Colors.red : Colors.green)),
                          ),
                        );
                      },
                    ),
              floatingActionButton: FloatingActionButton.extended(onPressed: _addKhataDialog, label: const Text('Add Khata'), icon: const Icon(Icons.add)),
            ),
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
                            trailing: Text('Rs ${item['cost']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        );
                      },
                    ),
              floatingActionButton: FloatingActionButton.extended(onPressed: _addMaintenanceDialog, label: const Text('Log Service'), icon: const Icon(Icons.build_circle)),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 5. AVG CALCULATOR SCREEN
// ----------------------------------------------------
class FuelAverageCalculatorScreen extends StatefulWidget {
  const FuelAverageCalculatorScreen({super.key});

  @override
  State<FuelAverageCalculatorScreen> createState() => _FuelAverageCalculatorScreenState();
}

class _FuelAverageCalculatorScreenState extends State<FuelAverageCalculatorScreen> {
  final _distanceController = TextEditingController();
  final _fuelController = TextEditingController();
  final _priceController = TextEditingController();

  double? _average;
  double? _costPerKm;

  void _calculate() {
    final dist = double.tryParse(_distanceController.text) ?? 0;
    final fuel = double.tryParse(_fuelController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (dist > 0 && fuel > 0) {
      setState(() {
        _average = dist / fuel;
        _costPerKm = price > 0 ? (fuel * price) / dist : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Average Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _distanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Distance Travelled (KM)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _fuelController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fuel Consumed (Liters)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fuel Price per Liter (Optional)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            ElevatedButton(onPressed: _calculate, child: const Text('Calculate')),
            const SizedBox(height: 20),
            if (_average != null) ...[
              Text('Average: ${_average!.toStringAsFixed(2)} KM/L', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_costPerKm != null) Text('Cost Per KM: Rs ${_costPerKm!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.blue)),
            ]
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 6. DIRECTORY & NOTES SCREEN
// ----------------------------------------------------
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
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title / Driver Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _contentController, decoration: const InputDecoration(labelText: 'Phone / Details', border: OutlineInputBorder()), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty) {
                setState(() {
                  _notes.add({'title': _titleController.text, 'content': _contentController.text});
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
      floatingActionButton: FloatingActionButton(onPressed: _addNote, child: const Icon(Icons.add)),
    );
  }
}

