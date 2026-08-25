import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
    _database = await _initDB('transport_manager_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final dbPathWithFile = path.join(dbPath, filePath);

    return await openDatabase(
      dbPathWithFile,
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
        type TEXT,
        is_deleted INTEGER DEFAULT 0
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
        date TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE khata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person TEXT,
        amount REAL,
        type TEXT,
        date TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertVehicle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('vehicles', row);
  }

  Future<int> updateVehicle(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('vehicles', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getVehicles({bool trash = false}) async {
    final db = await instance.database;
    return await db.query('vehicles', where: 'is_deleted = ?', whereArgs: [trash ? 1 : 0]);
  }

  Future<int> insertRecord(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('records', row);
  }

  Future<int> updateRecord(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('records', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRecords(int? vehicleId, {bool trash = false}) async {
    final db = await instance.database;
    if (vehicleId != null) {
      return await db.query('records', where: 'vehicle_id = ? AND is_deleted = ?', whereArgs: [vehicleId, trash ? 1 : 0]);
    }
    return await db.query('records', where: 'is_deleted = ?', whereArgs: [trash ? 1 : 0]);
  }

  Future<int> setSoftDelete(String table, int id, bool delete) async {
    final db = await instance.database;
    return await db.update(table, {'is_deleted': delete ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> permanentDelete(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}

// ----------------------------------------------------
// MAIN APP & NAVIGATION
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
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
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
    const RecycleBinScreen(),
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
          NavigationDestination(icon: Icon(Icons.analytics_rounded), label: 'Ledger'),
          NavigationDestination(icon: Icon(Icons.handshake_rounded), label: 'Services & Khata'),
          NavigationDestination(icon: Icon(Icons.delete_sweep_rounded), label: 'Recycle Bin'),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// FLEET DASHBOARD
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
    final data = await DatabaseHelper.instance.getVehicles();
    setState(() {
      _vehicles = data;
      _isLoading = false;
    });
  }

  void _showVehicleDialog([Map<String, dynamic>? existing]) {
    final numCtrl = TextEditingController(text: existing?['number']);
    final driverCtrl = TextEditingController(text: existing?['driver_name']);
    final phoneCtrl = TextEditingController(text: existing?['driver_phone']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Vehicle' : 'Edit Vehicle'),
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
                final payload = {
                  'number': numCtrl.text,
                  'driver_name': driverCtrl.text,
                  'driver_phone': phoneCtrl.text,
                  'type': 'Truck',
                };
                if (existing == null) {
                  await DatabaseHelper.instance.insertVehicle(payload);
                } else {
                  await DatabaseHelper.instance.updateVehicle(existing['id'], payload);
                }
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
              ? const Center(child: Text('No active vehicles found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _vehicles.length,
                  itemBuilder: (ctx, i) {
                    final v = _vehicles[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.directions_bus, size: 32, color: Colors.blue),
                        title: Text(v['number'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Driver: ${v['driver_name'] ?? 'N/A'} • ${v['driver_phone'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showVehicleDialog(v)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                await DatabaseHelper.instance.setSoftDelete('vehicles', v['id'], true);
                                _loadData();
                              },
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: v))),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVehicleDialog(),
        label: const Text('Add Vehicle'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
// ----------------------------------------------------
// VEHICLE DETAIL SCREEN
// ----------------------------------------------------
class VehicleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getRecords(widget.vehicle['id']);
    setState(() {
      _records = data;
      _isLoading = false;
    });
  }

  void _generatePdfAndPrint() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TRANSPORT INVOICE / REPORT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateTime.now().toString().split(' ')[0]),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Vehicle Number: ${widget.vehicle['number']}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Driver Name: ${widget.vehicle['driver_name'] ?? 'N/A'}'),
                pw.Text('Phone: ${widget.vehicle['driver_phone'] ?? 'N/A'}'),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Type', 'Category', 'Description / Note', 'Amount (Rs)'],
                  data: _records.map((r) => [
                    r['date'] ?? '',
                    r['type'] ?? '',
                    r['category'] ?? '',
                    r['note'] ?? '',
                    r['amount'].toString(),
                  ]).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _showTransactionDialog([Map<String, dynamic>? existing]) {
    String type = existing?['type'] ?? 'Expense';
    String category = existing?['category'] ?? 'Challan / Toll';
    final amountController = TextEditingController(text: existing != null ? existing['amount'].toString() : '');
    final noteController = TextEditingController(text: existing?['note'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setModalState) {
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
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(existing == null ? 'Add Transaction' : 'Edit Transaction', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          final payload = {
                            'vehicle_id': widget.vehicle['id'],
                            'type': type,
                            'category': category,
                            'amount': amt,
                            'note': noteController.text,
                            'date': existing?['date'] ?? DateTime.now().toString().split(' ')[0],
                          };

                          if (existing == null) {
                            await DatabaseHelper.instance.insertRecord(payload);
                          } else {
                            await DatabaseHelper.instance.updateRecord(existing['id'], payload);
                          }

                          if (mounted) Navigator.pop(dialogContext);
                          _loadRecords();
                        }
                      },
                      child: const Text('Save Entry'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle['number']} Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: _generatePdfAndPrint,
            tooltip: 'Print Invoice PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('No transactions for this vehicle yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _records.length,
                  itemBuilder: (ctx, i) {
                    final r = _records[i];
                    final isInc = r['type'] == 'Income';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isInc ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isInc ? Colors.green : Colors.red,
                        ),
                        title: Text('${r['category']} - Rs ${r['amount']}'),
                        subtitle: Text('${r['note'] ?? ''} • ${r['date']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showTransactionDialog(r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                await DatabaseHelper.instance.setSoftDelete('records', r['id'], true);
                                _loadRecords();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransactionDialog(),
        label: const Text('Add Entry'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// ----------------------------------------------------
// TOTAL LEDGER SCREEN
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
// SERVICES & UDHAR KHATA SCREEN
// ----------------------------------------------------
class ServicesAndKhataScreen extends StatefulWidget {
  const ServicesAndKhataScreen({super.key});

  @override
  State<ServicesAndKhataScreen> createState() => _ServicesAndKhataScreenState();
}

class _ServicesAndKhataScreenState extends State<ServicesAndKhataScreen> {
  final List<Map<String, String>> _khataEntries = [];
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  String _transactionType = 'Udhar (Gave)';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services & Khata')),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addKhataDialog,
        label: const Text('Add Khata'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// ----------------------------------------------------
// RECYCLE BIN SCREEN
// ----------------------------------------------------
class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  List<Map<String, dynamic>> _trashedVehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getVehicles(trash: true);
    setState(() {
      _trashedVehicles = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recycle Bin')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trashedVehicles.isEmpty
              ? const Center(child: Text('Recycle Bin is empty.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _trashedVehicles.length,
                  itemBuilder: (ctx, i) {
                    final v = _trashedVehicles[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.orange),
                        title: Text(v['number'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Driver: ${v['driver_name'] ?? 'N/A'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              onPressed: () async {
                     
