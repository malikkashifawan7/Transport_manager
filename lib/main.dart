import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportHisabProApp());
}

class TransportHisabProApp extends StatelessWidget {
  const TransportHisabProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Hisab Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainEnterpriseShell(),
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
    _database = await _initDB('transport_hisab_v12.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL,
        model TEXT,
        type TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        driver_phone TEXT,
        driver_cnic TEXT,
        location TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        party_name TEXT NOT NULL,
        route_from TEXT NOT NULL,
        route_to TEXT NOT NULL,
        goods_type TEXT,
        total_freight REAL NOT NULL,
        advance_paid REAL DEFAULT 0,
        commission REAL DEFAULT 0,
        booking_date TEXT NOT NULL,
        status TEXT DEFAULT 'Booked'
      )
    ''');

    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        main_category TEXT NOT NULL,
        sub_category TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        details TEXT,
        meter_reading REAL DEFAULT 0,
        litres REAL DEFAULT 0,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        shop_name TEXT,
        phone TEXT,
        address TEXT,
        city TEXT,
        udhar_balance REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        due_date TEXT NOT NULL,
        type TEXT NOT NULL,
        details TEXT
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles', orderBy: 'id DESC');
  }

  Future<int> addVehicle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('vehicles', row);
  }

  Future<int> updateVehicle(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('vehicles', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await instance.database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getBookings(int? vehicleId) async {
    final db = await instance.database;
    if (vehicleId == null) return await db.query('bookings', orderBy: 'id DESC');
    return await db.query('bookings', where: 'vehicle_id = ?', whereArgs: [vehicleId], orderBy: 'id DESC');
  }

  Future<int> addBooking(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('bookings', row);
  }

  Future<List<Map<String, dynamic>>> getRecords(int? vehicleId) async {
    final db = await instance.database;
    if (vehicleId == null) return await db.query('records', orderBy: 'id DESC');
    return await db.query('records', where: 'vehicle_id = ?', whereArgs: [vehicleId], orderBy: 'id DESC');
  }

  Future<int> addRecord(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('records', row);
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getVendors() async {
    final db = await instance.database;
    return await db.query('vendors', orderBy: 'id DESC');
  }

  Future<int> addVendor(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('vendors', row);
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final db = await instance.database;
    return await db.query('reminders', orderBy: 'due_date ASC');
  }

  Future<int> addReminder(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('reminders', row);
  }
}

// ==================== PDF REPORT ENGINE ====================
class PdfReportService {
  static Future<void> generateAndPrintVehicleLedger(
      Map<String, dynamic> vehicle, List<Map<String, dynamic>> records) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Transport Hisab Pro - Vehicle Statement',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Vehicle No: ${vehicle['number']} (${vehicle['type']})'),
              pw.Text('Driver Name: ${vehicle['driver_name']} | Contact: ${vehicle['driver_phone']}'),
              pw.SizedBox(height: 15),
              pw.Table.fromTextArray(
                headers: ['Date', 'Title', 'Category', 'Type', 'Amount (PKR)'],
                data: records
                    .map((r) => [
                          r['date'].toString(),
                          r['title'].toString(),
                          r['sub_category'].toString(),
                          r['type'].toString(),
                          r['amount'].toString()
                        ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}

// ==================== MAIN SHELL NAVIGATION ====================
class MainEnterpriseShell extends StatefulWidget {
  const MainEnterpriseShell({super.key});

  @override
  State<MainEnterpriseShell> createState() => _MainEnterpriseShellState();
}

class _MainEnterpriseShellState extends State<MainEnterpriseShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreenTab(),
    const FleetScreenTab(),
    const BookingsTab(),
    const DirectoryAndVendorsTab(),
    const RemindersTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey.shade600,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_add), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Directory'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
        ],
      ),
    );
  }
}

class HomeScreenTab extends StatefulWidget {
  const HomeScreenTab({super.key});

  @override
  State<HomeScreenTab> createState() => _HomeScreenTabState();
}

class _HomeScreenTabState extends State<HomeScreenTab> {
  String searchQuery = '';
  List<Map<String, dynamic>> vehicles = [];
  double totalIncome = 0;
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final v = await DatabaseHelper.instance.getVehicles();
    final r = await DatabaseHelper.instance.getRecords(null);

    double inc = 0;
    double exp = 0;

    for (var rec in r) {
      double amt = (rec['amount'] as num).toDouble();
      if (rec['type'] == 'Income') {
        inc += amt;
      } else {
        exp += amt;
      }
    }

    setState(() {
      vehicles = v;
      totalIncome = inc;
      totalExpense = exp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredVehicles = vehicles.where((v) {
      final num = v['number'].toString().toLowerCase();
      final drv = v['driver_name'].toString().toLowerCase();
      return num.contains(searchQuery.toLowerCase()) || drv.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Hisab Pro'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Vehicle or Driver...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              color: Colors.indigo.shade900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Total Enterprise Overview', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          const Text('Income', style: TextStyle(color: Colors.greenAccent)),
                          Text('Rs. ${totalIncome.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        Column(children: [
                          const Text('Expense', style: TextStyle(color: Colors.redAccent)),
                          Text('Rs. ${totalExpense.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        Column(children: [
                          const Text('Net Balance', style: TextStyle(color: Colors.white)),
                          Text('Rs. ${(totalIncome - totalExpense).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Fleet Quick View', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            filteredVehicles.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No vehicles found.')))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredVehicles.length,
                    itemBuilder: (context, index) {
                      final v = filteredVehicles[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.directions_bus, color: Colors.white)),
                          title: Text('${v['number']} (${v['type']})'),
                          subtitle: Text('Driver: ${v['driver_name']} | Loc: ${v['location']}'),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class FleetScreenTab extends StatefulWidget {
  const FleetScreenTab({super.key});

  @override
  State<FleetScreenTab> createState() => _FleetScreenTabState();
}

class _FleetScreenTabState extends State<FleetScreenTab> {
  List<Map<String, dynamic>> vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() async {
    final v = await DatabaseHelper.instance.getVehicles();
    setState(() => vehicles = v);
  }

  void _showAddEditVehicleDialog([Map<String, dynamic>? existing]) {
    final number = TextEditingController(text: existing?['number'] ?? '');
    final model = TextEditingController(text: existing?['model'] ?? '');
    final driver = TextEditingController(text: existing?['driver_name'] ?? '');
    final phone = TextEditingController(text: existing?['driver_phone'] ?? '');
    final cnic = TextEditingController(text: existing?['driver_cnic'] ?? '');
    final location = TextEditingController(text: existing?['location'] ?? '');
    String selectedType = existing?['type'] ?? '10-Wheeler';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Vehicle' : 'Edit Vehicle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: ['6-Wheeler', '10-Wheeler', 'Trailer', 'Container', 'Oil Tanker', 'Flatbed']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                TextField(controller: number, decoration: const InputDecoration(labelText: 'Vehicle Number')),
                TextField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
                TextField(controller: driver, decoration: const InputDecoration(labelText: 'Driver Name')),
                TextField(controller: phone, decoration: const InputDecoration(labelText: 'Driver Phone')),
                TextField(controller: cnic, decoration: const InputDecoration(labelText: 'Driver CNIC')),
                TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (number.text.isNotEmpty) {
                  final data = {
                    'number': number.text,
                    'model': model.text,
                    'type': selectedType,
                    'driver_name': driver.text,
                    'driver_phone': phone.text,
                    'driver_cnic': cnic.text,
                    'location': location.text,
                  };
                  if (existing == null) {
                    await DatabaseHelper.instance.addVehicle(data);
                  } else {
                    await DatabaseHelper.instance.updateVehicle(existing['id'], data);
                  }
                  _loadVehicles();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Management'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: vehicles.isEmpty
          ? const Center(child: Text('No vehicles added.'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return VehicleProfitCard(
                  vehicle: v,
                  onEdit: () => _showAddEditVehicleDialog(v),
                  onDelete: () async {
                    await DatabaseHelper.instance.deleteVehicle(v['id']);
                    _loadVehicles();
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditVehicleDialog(),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class VehicleProfitCard extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VehicleProfitCard({super.key, required this.vehicle, required this.onEdit, required this.onDelete});

  @override
  State<VehicleProfitCard> createState() => _VehicleProfitCardState();
}

class _VehicleProfitCardState extends State<VehicleProfitCard> {
  double income = 0;
  double expense = 0;
  double kmPerLitre = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    final recs = await DatabaseHelper.instance.getRecords(widget.vehicle['id']);
    double inc = 0;
    double exp = 0;
    double totalKm = 0;
    double totalLitres = 0;

    for (var r in recs) {
      double amt = (r['amount'] as num).toDouble();
      if (r['type'] == 'Income') {
        inc += amt;
      } else {
        exp += amt;
      }

      if (r['sub_category'] == 'Diesel filling') {
        totalKm += (r['meter_reading'] as num).toDouble();
        totalLitres += (r['litres'] as num).toDouble();
      }
    }

    setState(() {
      income = inc;
      expense = exp;
      kmPerLitre = totalLitres > 0 ? (totalKm / totalLitres) : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final net = income - expense;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.vehicle['number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
      
