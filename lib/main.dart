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
        primarySwatch: Colors.indigo,
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
    _database = await _initDB('transport_manager_v2.db');
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
        driver_phone TEXT,
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

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        party_name TEXT NOT NULL,
        party_phone TEXT,
        route TEXT NOT NULL,
        total_fare REAL NOT NULL,
        advance_paid REAL NOT NULL,
        booking_date TEXT NOT NULL,
        status TEXT DEFAULT 'Pending',
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
      )
    ''');
  }

  // Vehicles CRUD
  Future<int> addVehicle(String number, String driver, String phone) async {
    final db = await instance.database;
    return await db.insert('vehicles', {'number': number, 'driver_name': driver, 'driver_phone': phone});
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles', where: 'is_deleted = 0');
  }

  Future<int> updateVehicle(int id, String number, String driver, String phone) async {
    final db = await instance.database;
    return await db.update('vehicles', {'number': number, 'driver_name': driver, 'driver_phone': phone}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> softDeleteVehicle(int id) async {
    final db = await instance.database;
    return await db.update('vehicles', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // Ledger Records CRUD
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

  Future<int> updateRecord(int id, String type, String title, double amount, String details) async {
    final db = await instance.database;
    return await db.update('records', {
      'type': type,
      'title': title,
      'amount': amount,
      'details': details,
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
  Future<int> addBooking(int vehicleId, String party, String phone, String route, double total, double advance) async {
    final db = await instance.database;
    return await db.insert('bookings', {
      'vehicle_id': vehicleId,
      'party_name': party,
      'party_phone': phone,
      'route': route,
      'total_fare': total,
      'advance_paid': advance,
      'booking_date': DateTime.now().toIso8601String().substring(0, 10),
      'status': 'Pending'
    });
  }

  Future<List<Map<String, dynamic>>> getBookings(int vehicleId) async {
    final db = await instance.database;
    return await db.query('bookings', where: 'vehicle_id = ? AND is_deleted = 0', whereArgs: [vehicleId], orderBy: 'id DESC');
  }
}

// ==================== DASHBOARD SCREEN ====================
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
    setState(() => vehicles = data);
  }

  void _showAddVehicleDialog({Map<String, dynamic>? editVehicle}) {
    final numberController = TextEditingController(text: editVehicle?['number'] ?? '');
    final driverController = TextEditingController(text: editVehicle?['driver_name'] ?? '');
    final phoneController = TextEditingController(text: editVehicle?['driver_phone'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editVehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numberController, decoration: const InputDecoration(labelText: 'Gari Number (e.g. LES-1054)')),
            TextField(controller: driverController, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Driver Mobile Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (numberController.text.isNotEmpty) {
                if (editVehicle == null) {
                  await DatabaseHelper.instance.addVehicle(numberController.text, driverController.text, phoneController.text);
                } else {
                  await DatabaseHelper.instance.updateVehicle(editVehicle['id'], numberController.text, driverController.text, phoneController.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transport Hisab Pro')),
      body: vehicles.isEmpty
          ? const Center(child: Text('No vehicles added yet.'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
                    title: Text(v['number'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Driver: ${v['driver_name']} | Ph: ${v['driver_phone'] ?? "N/A"}'),
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
                            driverPhone: v['driver_phone'] ?? '',
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
// ==================== VEHICLE LEDGER & BOOKINGS SCREEN ====================
class VehicleLedgerScreen extends StatefulWidget {
  final int vehicleId;
  final String vehicleNumber;
  final String driverName;
  final String driverPhone;

  const VehicleLedgerScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.driverName,
    required this.driverPhone,
  });

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
    _loadData();
  }

  void _loadData() async {
    final recData = await DatabaseHelper.instance.getRecords(widget.vehicleId);
    final bookData = await DatabaseHelper.instance.getBookings(widget.vehicleId);
    
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
                  items: ['Income', 'Oil Change', 'Maintenance', 'Salary Advance', 'Other Expense']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
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
                  if (editRecord == null) {
                    await DatabaseHelper.instance.addRecord(widget.vehicleId, selectedType, titleController.text, amt, detailsController.text);
                  } else {
                    await DatabaseHelper.instance.updateRecord(editRecord['id'], selectedType, titleController.text, amt, detailsController.text);
                  }
                  _loadData();
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
    final routeController = TextEditingController();
    final fareController = TextEditingController();
    final advanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Advance Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: partyController, decoration: const InputDecoration(labelText: 'Party / Client Name')),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Party Phone Number')),
              TextField(controller: routeController, decoration: const InputDecoration(labelText: 'Route (e.g. Lahore to Multan)')),
              TextField(controller: fareController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Fare (Rs.)')),
              TextField(controller: advanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance Paid (Rs.)')),
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
                await DatabaseHelper.instance.addBooking(widget.vehicleId, partyController.text, phoneController.text, routeController.text, fare, adv);
                if (adv > 0) {
                  await DatabaseHelper.instance.addRecord(widget.vehicleId, 'Income', 'Booking Advance: ${partyController.text}', adv, 'Route: ${routeController.text}');
                }
                _loadData();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save Booking'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicleNumber),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Ledger Hisab'),
            Tab(icon: Icon(Icons.bookmark_added), text: 'Advance Bookings'),
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
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12.0)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Income: Rs. $totalIncome', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text('Expense: Rs. $totalExpense', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Text('NET PROFIT: Rs. $netProfit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: netProfit >= 0 ? Colors.indigo : Colors.red)),
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
                        subtitle: Text('Date: ${r['date']} | ${r['details']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Rs. ${r['amount']}', style: TextStyle(fontWeight: FontWeight.bold, color: isInc ? Colors.green : Colors.red)),
                            IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: () => _showRecordDialog(editRecord: r)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () async {
                              await DatabaseHelper.instance.softDeleteRecord(r['id']);
                              _loadData();
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
          
          // TAB 2: ADVANCE BOOKINGS
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
                      Text('Party: ${b['party_name']} (Ph: ${b['party_phone']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Route: ${b['route']}'),
                      Text('Booking Date: ${b['booking_date']}'),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total: Rs. ${b['total_fare']}'),
                          Text('Advance: Rs. ${b['advance_paid']}', style: const TextStyle(color: Colors.green)),
                          Text('Baqaya: Rs. $remaining', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

