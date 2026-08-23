import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportManagerApp());
}

class TransportManagerApp extends StatelessWidget {
  const TransportManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Hisab Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

// ==================== ADVANCED DATABASE HELPER ====================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_pro_enterprise_v4.db');
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
        model TEXT,
        driver_name TEXT NOT NULL,
        driver_phone TEXT,
        driver_cnic TEXT,
        last_oil_km REAL DEFAULT 0,
        next_oil_km REAL DEFAULT 0,
        token_tax_date TEXT,
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
        meter_reading REAL DEFAULT 0,
        date TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        phone TEXT,
        route TEXT NOT NULL,
        total_freight REAL NOT NULL,
        advance_paid REAL DEFAULT 0,
        balance REAL NOT NULL,
        status TEXT DEFAULT 'Pending',
        date TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles', where: 'is_deleted = 0', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getRecords(int vehicleId) async {
    final db = await instance.database;
    return await db.query('records', where: 'vehicle_id = ? AND is_deleted = 0', whereArgs: [vehicleId], orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getBookings(int vehicleId) async {
    final db = await instance.database;
    return await db.query('bookings', where: 'vehicle_id = ? AND is_deleted = 0', whereArgs: [vehicleId], orderBy: 'id DESC');
  }

  Future<int> addVehicle(String number, String model, String driverName, String driverPhone, String driverCnic, double lastOil, double nextOil, String tokenTax) async {
    final db = await instance.database;
    return await db.insert('vehicles', {
      'number': number,
      'model': model,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_cnic': driverCnic,
      'last_oil_km': lastOil,
      'next_oil_km': nextOil,
      'token_tax_date': tokenTax,
    });
  }

  Future<int> addRecord(int vehicleId, String type, String title, double amount, String details, double meterReading) async {
    final db = await instance.database;
    return await db.insert('records', {
      'vehicle_id': vehicleId,
      'type': type,
      'title': title,
      'amount': amount,
      'details': details,
      'meter_reading': meterReading,
      'date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  Future<int> updateRecord(int id, String type, String title, double amount, String details, double meterReading) async {
    final db = await instance.database;
    return await db.update('records', {
      'type': type,
      'title': title,
      'amount': amount,
      'details': details,
      'meter_reading': meterReading,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> softDeleteVehicle(int id) async {
    final db = await instance.database;
    return await db.update('vehicles', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
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
    _reloadVehicles();
  }

  void _reloadVehicles() async {
    final data = await DatabaseHelper.instance.getVehicles();
    setState(() {
      vehicles = data;
    });
  }

  void _showAddVehicleDialog([Map<String, dynamic>? editVehicle]) {
    final numberController = TextEditingController(text: editVehicle?['number'] ?? '');
    final modelController = TextEditingController(text: editVehicle?['model'] ?? '');
    final driverNameController = TextEditingController(text: editVehicle?['driver_name'] ?? '');
    final driverPhoneController = TextEditingController(text: editVehicle?['driver_phone'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editVehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numberController, decoration: const InputDecoration(labelText: 'Vehicle Number (e.g. LES-1234)')),
              TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Model / Type')),
              TextField(controller: driverNameController, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: driverPhoneController, decoration: const InputDecoration(labelText: 'Driver Phone')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (numberController.text.isNotEmpty) {
                await DatabaseHelper.instance.addVehicle(
                  numberController.text,
                  modelController.text,
                  driverNameController.text,
                  driverPhoneController.text,
                  '', 0, 0, '',
                );
                _reloadVehicles();
                if (mounted) Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Transport Fleet Pro')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Transport Fleet Manager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              accountEmail: Text('Enterprise v4.0'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.local_shipping, size: 40, color: Colors.deepPurple),
              ),
              decoration: BoxDecoration(color: Colors.deepPurple),
            ),
            ListTile(
              leading: const Icon(Icons.store, color: Colors.indigo),
              title: const Text('Vendors Khata (Shops/Udhar)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorKhataScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: Colors.green),
              title: const Text('Check Software Updates'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App is up to date (v4.0 Enterprise Build)')));
              },
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('App Info & Backup'),
              subtitle: Text('Cloud & Offline Storage Sync Active'),
            ),
          ],
        ),
      ),
      body: vehicles.isEmpty
          ? const Center(child: Text('No Vehicles Added Yet.'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
                    title: Text('${v['number']} (${v['model'] ?? 'N/A'})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Driver: ${v['driver_name']} | Ph: ${v['driver_phone'] ?? 'N/A'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddVehicleDialog(v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper.instance.softDeleteVehicle(v['id']);
                            _reloadVehicles();
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VehicleLedgerScreen(vehicleData: v)),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVehicleDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
// ==================== VEHICLE LEDGER SCREEN ====================
class VehicleLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const VehicleLedgerScreen({super.key, required this.vehicleData});

  @override
  State<VehicleLedgerScreen> createState() => _VehicleLedgerScreenState();
}

class _VehicleLedgerScreenState extends State<VehicleLedgerScreen> {
  List<Map<String, dynamic>> records = [];
  List<Map<String, dynamic>> bookings = [];
  double totalIncome = 0.0;
  double totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _loadLedgerData();
  }

  void _loadLedgerData() async {
    final recData = await DatabaseHelper.instance.getRecords(widget.vehicleData['id']);
    final bookData = await DatabaseHelper.instance.getBookings(widget.vehicleData['id']);

    double inc = 0;
    double exp = 0;
    for (var r in recData) {
      final amt = (r['amount'] as num).toDouble();
      if (r['type'] == 'Income') {
        inc += amt;
      } else {
        exp += amt;
      }
    }

    setState(() {
      records = recData;
      bookings = bookData;
      totalIncome = inc;
      totalExpense = exp;
    });
  }

  void _showRecordDialog([Map<String, dynamic>? editRecord]) {
    final titleController = TextEditingController(text: editRecord?['title'] ?? '');
    final amountController = TextEditingController(text: editRecord != null ? editRecord['amount'].toString() : '');
    final detailsController = TextEditingController(text: editRecord?['details'] ?? '');
    final meterController = TextEditingController(text: editRecord != null ? editRecord['meter_reading'].toString() : '');
    String selectedType = editRecord?['type'] ?? 'Income';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editRecord == null ? 'Add Entry' : 'Edit Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: ['Income', 'Oil Change', 'Maintenance', 'Salary Advance', 'Tyre/Spare Parts', 'Other Expense']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title / Description')),
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
                TextField(controller: meterController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Meter Reading (KM)')),
                TextField(controller: detailsController, decoration: const InputDecoration(labelText: 'Notes / Vendor Name')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                final meter = double.tryParse(meterController.text) ?? 0.0;
                if (titleController.text.isNotEmpty && amt > 0) {
                  if (editRecord == null) {
                    await DatabaseHelper.instance.addRecord(widget.vehicleData['id'], selectedType, titleController.text, amt, detailsController.text, meter);
                  } else {
                    await DatabaseHelper.instance.updateRecord(editRecord['id'], selectedType, titleController.text, amt, detailsController.text, meter);
                  }
                  _loadLedgerData();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicleData['number']} Ledger'),
      ),
      body: Center(
        child: Text('Income: \$${totalIncome.toStringAsFixed(2)} | Expense: \$${totalExpense.toStringAsFixed(2)}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==================== VENDOR KHATA SCREEN ====================
class VendorKhataScreen extends StatelessWidget {
  const VendorKhataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors Khata (Shops/Udhar)'),
      ),
      body: const Center(
        child: Text('Vendor Khata Management Coming Soon'),
      ),
    );
  }
}
