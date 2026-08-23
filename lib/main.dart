import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportManagerApp());
}

class TransportManagerApp extends StatelessWidget {
  const TransportManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Hisab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

// ==================== DATABASE HELPER ====================
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
    final path = p.join(dbPath, filePath);

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
        driver_name TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        type TEXT NOT NULL, 
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        details TEXT,
        date TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
      )
    ''');
  }

  Future<int> addVehicle(String number, String driver) async {
    final db = await instance.database;
    return await db.insert('vehicles', {'number': number, 'driver_name': driver});
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles', where: 'is_deleted = 0');
  }

  Future<int> updateVehicle(int id, String number, String driver) async {
    final db = await instance.database;
    return await db.update('vehicles', {'number': number, 'driver_name': driver}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> softDeleteVehicle(int id) async {
    final db = await instance.database;
    return await db.update('vehicles', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addRecord(int vehicleId, String type, String title, double amount, String details) async {
    final db = await instance.database;
    return await db.insert('records', {
      'vehicle_id': vehicleId,
      'type': type,
      'title': title,
      'amount': amount,
      'details': details,
      'date': DateTime.now().toIso8601String().substring(0, 10),
    });
  }

  Future<List<Map<String, dynamic>>> getRecords(int vehicleId) async {
    final db = await instance.database;
    return await db.query('records', where: 'vehicle_id = ? AND is_deleted = 0', whereArgs: [vehicleId], orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getAllAdvanceRecords() async {
    final db = await instance.database;
    return await db.query('records', where: 'type = "Salary Advance" AND is_deleted = 0', orderBy: 'id DESC');
  }

  Future<int> softDeleteRecord(int id) async {
    final db = await instance.database;
    return await db.update('records', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getDeletedVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles', where: 'is_deleted = 1');
  }

  Future<int> restoreVehicle(int id) async {
    final db = await instance.database;
    return await db.update('vehicles', {'is_deleted': 0}, where: 'id = ?', whereArgs: [id]);
  }
}

// ==================== MAIN HOME SCREEN ====================
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  List<Map<String, dynamic>> vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() async {
    final data = await DatabaseHelper.instance.getVehicles();
    setState(() {
      vehicles = data;
    });
  }

  void _showAddVehicleDialog({Map<String, dynamic>? editVehicle}) {
    final numberController = TextEditingController(text: editVehicle?['number'] ?? '');
    final driverController = TextEditingController(text: editVehicle?['driver_name'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editVehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numberController, decoration: const InputDecoration(labelText: 'Gari Number (e.g. LES-1054)')),
            TextField(controller: driverController, decoration: const InputDecoration(labelText: 'Driver Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (numberController.text.isNotEmpty) {
                if (editVehicle == null) {
                  await DatabaseHelper.instance.addVehicle(numberController.text, driverController.text);
                } else {
                  await DatabaseHelper.instance.updateVehicle(editVehicle['id'], numberController.text, driverController.text);
                }
                _loadVehicles();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _openGoogleMaps() async {
    final Uri url = Uri.parse('https://www.google.com/maps');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Maps')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Hisab - Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Google Maps Navigation',
            onPressed: _openGoogleMaps,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Recycle Bin',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
              ).then((_) => _loadVehicles());
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Transport Hisab'),
              accountEmail: Text('v2.0 Advanced Fleet Manager'),
              currentAccountPicture: CircleAvatar(child: Icon(Icons.local_shipping, size: 36)),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Driver Salary Advances'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalaryAdvanceLedgerScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Auto Update Check'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App is up to date (Version 2.0.0)')));
              },
            ),
          ],
        ),
      ),
      body: vehicles.isEmpty
          ? const Center(child: Text('No vehicles added yet. Click + to add.'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                    title: Text(v['number'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Driver: ${v['driver_name']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddVehicleDialog(editVehicle: v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper.instance.softDeleteVehicle(v['id']);
                            _loadVehicles();
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VehicleLedgerScreen(
                            vehicleId: v['id'],
                            vehicleNumber: v['number'],
                            driverName: v['driver_name'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }
}

// ==================== VEHICLE LEDGER & AUTO CALCULATOR ====================
class VehicleLedgerScreen extends StatefulWidget {
  final int vehicleId;
  final String vehicleNumber;
  final String driverName;

  const VehicleLedgerScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.driverName,
  });

  @override
  State<VehicleLedgerScreen> createState() => _VehicleLedgerScreenState();
}

class _VehicleLedgerScreenState extends State<VehicleLedgerScreen> {
  List<Map<String, dynamic>> records = [];
  double totalIncome = 0.0;
  double totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() async {
    final data = await DatabaseHelper.instance.getRecords(widget.vehicleId);
    double inc = 0;
    double exp = 0;
    for (var r in data) {
      if (r['type'] == 'Income') {
        inc += r['amount'];
      } else {
        exp += r['amount'];
      }
    }
    setState(() {
      records = data;
      totalIncome = inc;
      totalExpense = exp;
    });
  }

  void _addRecordDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final detailsController = TextEditingController();
    String selectedType = 'Income';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Transaction / Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: ['Income', 'Oil Change', 'Maintenance', 'Salary Advance', 'Other Expense']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title / Sub-category')),
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs.)')),
                TextField(controller: detailsController, decoration: const InputDecoration(labelText: 'Details / Meter Reading')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (titleController.text.isNotEmpty && amt > 0) {
                  await DatabaseHelper.instance.addRecord(
                    widget.vehicleId,
                    selectedType,
                    titleController.text,
                    amt,
                    detailsController.text,
                  );
                  _loadRecords();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save Record'),
            )
          ],
        ),
      ),
    );
  }

  void _shareSummary() {
    final net = totalIncome - totalExpense;
    final text = '*** Vehicle Ledger Summary ***\nVehicle: ${widget.vehicleNumber}\nDriver: ${widget.driverName}\nTotal Income: Rs. $totalIncome\nTotal Expenses: Rs. $totalExpense\nNET PROFIT: Rs. $net\n\nGenerated via Transport Hisab';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicleNumber} - Pro Ledger'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareSummary, tooltip: 'Share Summary'),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Income: Rs. $totalIncome', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Expense: Rs. $totalExpense', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'NET PROFIT (SAFI BACHAT): Rs. $netProfit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: netProfit >= 0 ? Colors.indigo : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
              onPressed: _addRecordDialog,
              icon: const Icon(Icons.add_card),
              label: const Text('Add Entry (Income, Oil Change, Advance, Maintenance)'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: records.isEmpty
                ? const Center(child: Text('No ledger entries recorded.'))
                : ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final r = records[index];
                      final isInc = r['type'] == 'Income';
                      final double amt = r['amount'] is int ? (r['amount'] as int).toDouble() : (r['amount'] ?? 0.0);
                      final String titleStr = r['title'] ?? '';
                      final String typeStr = r['type'] ?? '';
                      final String dateStr = r['date'] ?? '';
                      final String detailsStr = r['details'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isInc ? Colors.green.shade100 : Colors.red.shade100,
                            child: Icon(
                              isInc ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isInc ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text('$titleStr [$typeStr]', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Date: $dateStr | Details: $detailsStr'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rs. $amt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isInc ? Colors.green : Colors.red,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                onPressed: () async {
                                  await DatabaseHelper.instance.softDeleteRecord(r['id']);
                                  _loadRecords();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== ALL DRIVERS SALARY ADVANCE ====================
class SalaryAdvanceLedgerScreen extends StatefulWidget {
  const SalaryAdvanceLedgerScreen({super.key});

  @override
  State<SalaryAdvanceLedgerScreen> createState() => _SalaryAdvanceLedgerScreenState();
}

class _SalaryAdvanceLedgerScreenState extends State<SalaryAdvanceLedgerScreen> {
  List<Map<String, dynamic>> advances = [];

  @override
  void initState() {
    super.initState();
    _loadAdvances();
  }

  void _loadAdvances() async {
    final data = await DatabaseHelper.instance.getAllAdvanceRecords();
    setState(() {
      advances = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Salary Advances Ledger')),
      body: advances.isEmpty
          ? const Center(child: Text('No advance payments recorded.'))
          : ListView.builder(
              itemCount: advances.length,
              itemBuilder: (context, index) {
                fina
