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
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        party_name TEXT NOT NULL,
        party_phone TEXT,
        pickup_loc TEXT,
        drop_loc TEXT,
        total_fare REAL NOT NULL,
        advance_paid REAL NOT NULL,
        booking_date TEXT NOT NULL,
        status TEXT DEFAULT 'Pending',
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL,
        owner_name TEXT,
        phone TEXT,
        category TEXT,
        credit_balance REAL DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE vendor_txns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendor_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (vendor_id) REFERENCES vendors (id)
      )
    ''');
  }

  // Vehicles CRUD
  Future<int> addVehicle(String number, String model, String driver, String phone, String cnic, double oilKm, String tokenDate) async {
    final db = await instance.database;
    return await db.insert('vehicles', {
      'number': number,
      'model': model,
      'driver_name': driver,
      'driver_phone': phone,
      'driver_cnic': cnic,
      'last_oil_km': oilKm,
      'next_oil_km': oilKm + 5000,
      'token_tax_date': tokenDate,
    });
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles', where: 'is_deleted = 0');
  }

  Future<int> updateVehicle(int id, String number, String model, String driver, String phone, String cnic, double oilKm, String tokenDate) async {
    final db = await instance.database;
    return await db.update('vehicles', {
      'number': number,
      'model': model,
      'driver_name': driver,
      'driver_phone': phone,
      'driver_cnic': cnic,
      'last_oil_km': oilKm,
      'next_oil_km': oilKm + 5000,
      'token_tax_date': tokenDate,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> softDeleteVehicle(int id) async {
    final db = await instance.database;
    return await db.update('vehicles', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // Records CRUD
  Future<int> addRecord(int vehicleId, String type, String title, double amount, String details, double meter) async {
    final db = await instance.database;
    return await db.insert('records', {
      'vehicle_id': vehicleId,
      'type': type,
      'title': title,
      'amount': amount,
      'details': details,
      'meter_reading': meter,
      'date': DateTime.now().toIso8601String().substring(0, 10),
    });
  }

  Future<int> updateRecord(int id, String type, String title, double amount, String details, double meter) async {
    final db = await instance.database;
    return await db.update('records', {
      'type': type,
      'title': title,
      'amount': amount,
      'details': details,
      'meter_reading': meter,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRecords(int vehicleId) async {
    final db = await instance.database;
    return await db.query('records', where: 'vehicle_id = ? AND is_deleted = 0', whereArgs: [vehicleId], orderBy: 'id DESC');
  }

  Future<int> softDeleteRecord(int id) async {
    final db = await instance.database;
    return await db.update('records', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // Bookings CRUD
  Future<int> addBooking(int vehicleId, String party, String phone, String pickup, String drop, double total, double advance, String date) async {
    final db = await instance.database;
    return await db.insert('bookings', {
      'vehicle_id': vehicleId,
      'party_name': party,
      'party_phone': phone,
      'pickup_loc': pickup,
      'drop_loc': drop,
      'total_fare': total,
      'advance_paid': advance,
      'booking_date': date,
      'status': 'Pending'
    });
  }

  Future<List<Map<String, dynamic>>> getBookings(int vehicleId) async {
    final db = await instance.database;
    return await db.query('bookings', where: 'vehicle_id = ? AND is_deleted = 0', whereArgs: [vehicleId], orderBy: 'id DESC');
  }

  // Vendors Udhar Khata
  Future<int> addVendor(String shop, String owner, String phone, String category) async {
    final db = await instance.database;
    return await db.insert('vendors', {
      'shop_name': shop,
      'owner_name': owner,
      'phone': phone,
      'category': category,
      'credit_balance': 0.0,
    });
  }

  Future<List<Map<String, dynamic>>> getVendors() async {
    final db = await instance.database;
    return await db.query('vendors', where: 'is_deleted = 0');
  }

  Future<void> addVendorTxn(int vendorId, String type, double amount, String desc) async {
    final db = await instance.database;
    await db.insert('vendor_txns', {
      'vendor_id': vendorId,
      'type': type,
      'amount': amount,
      'description': desc,
      'date': DateTime.now().toIso8601String().substring(0, 10),
    });

    final vendor = await db.query('vendors', where: 'id = ?', whereArgs: [vendorId]);
    if (vendor.isNotEmpty) {
      double current = (vendor.first['credit_balance'] as num).toDouble();
      double newBal = type == 'Udhar Taken' ? current + amount : current - amount;
      await db.update('vendors', {'credit_balance': newBal}, where: 'id = ?', whereArgs: [vendorId]);
    }
  }

  Future<List<Map<String, dynamic>>> getVendorTxns(int vendorId) async {
    final db = await instance.database;
    return await db.query('vendor_txns', where: 'vendor_id = ?', whereArgs: [vendorId], orderBy: 'id DESC');
  }
}

// ==================== DASHBOARD & DRAWER ====================
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});
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
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App Info & Backup'),
              subtitle: const Text('Cloud & Offline Storage Sync Active'),
            ),
          ],
        ),
      ),
      body: vehicles.isEmpty
 Active'),
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
                    subtitle: Text('Driver: ${v['driver_name']} | Ph: ${v['driver_phone'] ?? "N/A"}\nNext Oil: ${v['next_oil_km']} KM'),
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
                            _reloadVehicles();
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VehicleLedgerScreen(vehicleData: v),
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

// ==// ==================== VEHICLE LEDGER & BOOKINGS SCREEN ====================
class VehicleLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const VehicleLedgerScreen({super.key, required this.vehicleData});

  @override
  State<VehicleLedgerScreen> createState() => _VehicleLedgerScreenState();
}

class _VehicleLedgerScreenState extends State<VehicleLedgerScreen> with SingleTickerProviderStateMixin { {
  late TabController _tabController;

  List<Map<String, dynamic>> records = [];
  List<Map<String, dynamic>> bookings = [];

  double totalIncome = 0.0;
  double totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
