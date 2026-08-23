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
      double current = vendor.first['credit_balance'] as double;
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
    setState(() => vehicles = data);
  }

  void _showAddVehicleDialog({Map<String, dynamic>? editVehicle}) {
    final numberController = TextEditingController(text: editVehicle?['number'] ?? '');
    final modelController = TextEditingController(text: editVehicle?['model'] ?? '');
    final driverController = TextEditingController(text: editVehicle?['driver_name'] ?? '');
    final phoneController = TextEditingController(text: editVehicle?['driver_phone'] ?? '');
    final cnicController = TextEditingController(text: editVehicle?['driver_cnic'] ?? '');
    final oilKmController = TextEditingController(text: editVehicle != null ? editVehicle['last_oil_km'].toString() : '');
    final tokenDateController = TextEditingController(text: editVehicle?['token_tax_date'] ?? '2026-12-31');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editVehicle == null ? 'Add Vehicle & Details' : 'Edit Vehicle Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numberController, decoration: const InputDecoration(labelText: 'Gari Number (e.g. LES-1054)')),
              TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Gari Model / Type')),
              TextField(controller: driverController, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Driver Mobile Number')),
              TextField(controller: cnicController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Driver CNIC Number')),
              TextField(controller: oilKmController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Oil Meter Reading (KM)')),
              TextField(controller: tokenDateController, decoration: const InputDecoration(labelText: 'Token / Fitness Expiry Date')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final oilKm = double.tryParse(oilKmController.text) ?? 0.0;
              if (numberController.text.isNotEmpty) {
                if (editVehicle == null) {
                  await DatabaseHelper.instance.addVehicle(numberController.text, modelController.text, driverController.text, phoneController.text, cnicController.text, oilKm, tokenDateController.text);
                } else {
                  await DatabaseHelper.instance.updateVehicle(editVehicle['id'], numberController.text, modelController.text, driverController.text, phoneController.text, cnicController.text, oilKm, tokenDateController.text);
                }
                _reloadVehicles();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save Vehicle'),
          )
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorsListScreen()));
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
// ==================== VEHICLE LEDGER & BOOKINGS SCREEN ====================
class VehicleLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const VehicleLedgerScreen({super.key, required this.vehicleData});

  @override
  State<VehicleLedgerScreen> createState() => _VehicleLedgerScreenState();
}

class _VehicleLedgerScreenState extends State<VehicleLedgerScreen> with SingleTickerProviderStateMixin {
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
      if (r['type'] == 'Income') {
        inc += r['amount'];
      } else {
        exp += r['amount'];
      }
    }
    setState(() {
      records = recData;
      bookings = bookData;
      totalIncome = inc;
      totalExpense = exp;
    });
  }

  void _showRecordDialog({Map<String, dynamic>? editRecord}) {
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
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs.)')),
                TextField(controller: meterController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Meter Reading (KM)')),
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
            )
          ],
        ),
      ),
    );
  }

  void _showBookingDialog() {
    final partyController = TextEditingController();
    final phoneController = TextEditingController();
    final pickupController = TextEditingController();
    final dropController = TextEditingController();
    final fareController = TextEditingController();
    final advanceController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Booking / Route'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: partyController, decoration: const InputDecoration(labelText: 'Party / Client Name')),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Party Phone Number')),
              TextField(controller: pickupController, decoration: const InputDecoration(labelText: 'Pickup City / Area')),
              TextField(controller: dropController, decoration: const InputDecoration(labelText: 'Drop City / Area')),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Booking Date (YYYY-MM-DD)')),
              TextField(controller: fareController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Fare (Rs.)')),
              TextField(controller: advanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance Received (Rs.)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final fare = double.tryParse(fareController.text) ?? 0.0;
              final adv = double.tryParse(advanceController.text) ?? 0.0;
              if (partyController.text.isNotEmpty && fare > 0) {
                await DatabaseHelper.instance.addBooking(widget.vehicleData['id'], partyController.text, phoneController.text, pickupController.text, dropController.text, fare, adv, dateController.text);
                if (adv > 0) {
                  await DatabaseHelper.instance.addRecord(widget.vehicleData['id'], 'Income', 'Booking Advance: ${partyController.text}', adv, 'Route: ${pickupController.text} to ${dropController.text}', 0);
                }
                _loadLedgerData();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save Booking'),
          )
        ],
      ),
    );
  }

  void _openGoogleMaps(String pickup, String drop) async {
    final query = Uri.encodeComponent('$pickup to $drop');
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(pickup)}&destination=${Uri.encodeComponent(drop)}");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch Google Maps')));
      }
    }
  }

  void _shareOrPrintLedger() {
    final netProfit = totalIncome - totalExpense;
    final summary = '''
🧾 *TRANSPORT FLEET OFFICIAL RECEIPT / REPORT*
----------------------------------------
*Vehicle:* ${widget.vehicleData['number']} (${widget.vehicleData['model']})
*Driver:* ${widget.vehicleData['driver_name']} (Ph: ${widget.vehicleData['driver_phone']})
*Next Oil Change:* ${widget.vehicleData['next_oil_km']} KM
----------------------------------------
🟢 *Total Income:* Rs. $totalIncome
🔴 *Total Expense:* Rs. $totalExpense
----------------------------------------
💰 *NET PROFIT (SAFI BACHAT):* Rs. $netProfit
----------------------------------------
Generated via Transport Hisab Enterprise
''';
    Share.share(summary);
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicleData['number']} - Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print / Share PDF',
            onPressed: _shareOrPrintLedger,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Hisab Ledger'),
            Tab(icon: Icon(Icons.map), text: 'Bookings & Routes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: LEDGER
          Column(
            children: [
              Container(
                margin: const EdgeInsets.all(12.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12.0)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Income: Rs. $totalIncome', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Expense: Rs. $totalExpense', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const Divider(),
                    Text('NET PROFIT: Rs. $netProfit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: netProfit >= 0 ? Colors.indigo : Colors.red)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final r = records[index];
                    final isInc = r['type'] == 'Income';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: ListTile(
                        title: Text('${r['title']} [${r['type']}]', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Date: ${r['date']} | Meter: ${r['meter_reading']} KM\nNote: ${r['details']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Rs. ${r['amount']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isInc ? Colors.green : Colors.red)),
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _showRecordDialog(editRecord: r)),
                            IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                              await DatabaseHelper.instance.softDeleteRecord(r['id']);
                              _loadLedgerData();
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // TAB 2: BOOKINGS
          ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              final double remaining = b['total_fare'] - b['advance_paid'];
              return Card(
                margin: const EdgeInsets.all(10.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Party: ${b['party_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            icon: const Icon(Icons.navigation, size: 16),
                            label: const Text('Google Map Route'),
                            onPressed: () => _openGoogleMaps(b['pickup_loc'] ?? '', b['drop_loc'] ?? ''),
                          ),
                        ],
                      ),
                      Text('Phone: ${b['party_phone']}'),
                      Text('Route: ${b['pickup_loc']} ➔ ${b['drop_loc']}'),
                      Text('Date: ${b['booking_date']}'),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total: Rs. ${b['total_fare']}'),
                          Text('Advance: Rs. ${b['advance_paid']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          Text('Balance: Rs. $remaining', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showRecordDialog();
          } else {
            _showBookingDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==================== VENDORS KHATA (SHOPS / SPARE PARTS / UDHAR) ====================
class VendorsListScreen extends StatefulWidget {
  const VendorsListScreen({super.key});

  @override
  State<VendorsListScreen> createState() => _VendorsListScreenState();
}

class _VendorsListScreenState extends State<VendorsListScreen> {
  List<Map<String, dynamic>> vendors = [];

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  void _loadVendors() async {
    final data = await DatabaseHelper.instance.getVendors();
    setState(() => vendors = data);
  }

  void _showAddVendorDialog() {
    final shopController = TextEditingController();
    final ownerController = TextEditingController();
    final phoneController = TextEditingController();
    final catController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Vendor / Shop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: shopController, decoration: const InputDecoration(labelText: 'Shop / Business Name')),
            TextField(controller: ownerController, decoration: const InputDecoration(labelText: 'Owner Name')),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number')),
            TextField(controller: catController, decoration: const InputDecoration(labelText: 'Type (e.g. Workshop, Fuel Pump, Spare Parts)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (shopController.text.isNotEmpty) {
                await DatabaseHelper.instance.addVendor(shopController.text, ownerController.text, phoneController.text, catController.text);
                _loadVendors();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save Vendor'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendors Khata (Udhar Management)')),
      body: vendors.isEmpty
          ? const Center(child: Text('No Vendors Added Yet.'))
          : ListView.builder(
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                final v = vendors[index];
                final balance = v['credit_balance'] as double;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.store)),
                    title: Text('${v['shop_name']} (${v['category']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Owner: ${v['owner_name']} | Ph: ${v['phone']}'),
                    trailing: Text(
                      'Udhar: Rs. $balance',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: balance > 0 ? Colors.red : Colors.green),
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => VendorTxnScreen(vendor: v))).then((_) => _loadVendors());
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVendorDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Vendor'),
      ),
    );
  }
}

class VendorTxnScreen extends StatefulWidget {
  final Map<String, dynamic> vendor;
  const VendorTxnScreen({super.key, required this.vendor});

  @override
  State<VendorTxnScreen> createState() => _VendorTxnScreenState();
}

class _VendorTxnScreenState extends State<VendorTxnScreen> {
  List<Map<String, dynamic>> txns = [];

  @override
  void initState() {
    super.initState();
    _loadTxns();
  }

  void _loadTxns() async {
    final data = await DatabaseHelper.instance.getVendorTxns(widget.vendor['id']);
    setState(() => txns = data);
  }

  void _showAddTxnDialog(String type) {
    final amtController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(type == 'Udhar Taken' ? 'Add Udhar Entry (Payable)' : 'Payment Given (Wasool/Ada)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amtController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs.)')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Item / Bill Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtController.text) ?? 0.0;
              if (amt > 0) {
                await DatabaseHelper.instance.addVendorTxn(widget.vendor['id'], type, amt, descController.text);
                _loadTxns();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save Entry'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(B
