import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportHisabProApp());
}

class TransportHisabProApp extends StatelessWidget {
  const TransportHisabProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Hisab Pro Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainEnterpriseShell(),
    );
  }
}

// ==================== ENTERPRISE DATABASE HELPER ====================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_hisab_enterprise_v5.db');
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
        type TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        driver_phone TEXT,
        location TEXT,
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
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        details TEXT,
        meter_reading REAL DEFAULT 0,
        date TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        shop_name TEXT,
        phone TEXT,
        city TEXT,
        udhar_balance REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        date TEXT NOT NULL,
        is_reminder INTEGER DEFAULT 0
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

  Future<List<Map<String, dynamic>>> getVendors() async {
    final db = await instance.database;
    return await db.query('vendors', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await instance.database;
    return await db.query('notes', orderBy: 'id DESC');
  }

  Future<int> addVehicle(String number, String model, String type, String driverName, String driverPhone, String location) async {
    final db = await instance.database;
    return await db.insert('vehicles', {
      'number': number,
      'model': model,
      'type': type,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'location': location,
    });
  }

  Future<int> addRecord(int vehicleId, String type, String category, String title, double amount, String details, double meter) async {
    final db = await instance.database;
    return await db.insert('records', {
      'vehicle_id': vehicleId,
      'type': type,
      'category': category,
      'title': title,
      'amount': amount,
      'details': details,
      'meter_reading': meter,
      'date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  Future<int> addVendor(String name, String shop, String phone, String city, double balance) async {
    final db = await instance.database;
    return await db.insert('vendors', {
      'name': name,
      'shop_name': shop,
      'phone': phone,
      'city': city,
      'udhar_balance': balance,
    });
  }

  Future<int> addNote(String title, String content, bool isReminder) async {
    final db = await instance.database;
    return await db.insert('notes', {
      'title': title,
      'content': content,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'is_reminder': isReminder ? 1 : 0,
    });
  }

  Future<int> deleteVehicle(int id) async {
    final db = await instance.database;
    return await db.update('vehicles', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}

// ==================== MAIN SHELL WITH TABS ====================
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
    const VendorsKhataTab(),
    const ToolsAndCalculatorTab(),
    const RemindersAndNotesTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Vendors'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Tools'),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: 'Notes'),
        ],
      ),
    );
  }
}

// ==================== DASHBOARD TAB ====================
class HomeScreenTab extends StatelessWidget {
  const HomeScreenTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transport Hisab Pro Plus'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.indigo.shade800,
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text('Enterprise Fleet Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [Text('Active Fleet', style: TextStyle(color: Colors.white70)), Text('12', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
                        Column(children: [Text('Active Trips', style: TextStyle(color: Colors.white70)), Text('5', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
                        Column(children: [Text('Net Profit', style: TextStyle(color: Colors.greenAccent)), Text('Rs. 450k', style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold))]),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Enterprise Features Quick Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildQuickCard(context, Icons.map, 'Map Tracking', Colors.orange, () => _openMapModal(context)),
                _buildQuickCard(context, Icons.calendar_month, 'Trip Calendar', Colors.purple, () => _openCalendarModal(context)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        onTap: onTap,
      ),
    );
  }

  static void _openMapModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        height: 300,
        child: const Column(
          children: [
            Icon(Icons.map_outlined, size: 60, color: Colors.indigo),
            SizedBox(height: 10),
            Text('GPS Fleet Map View', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Live location tracking for Lahore, Karachi, Multan & Islamabad fleets connected.'),
          ],
        ),
      ),
    );
  }

  static void _openCalendarModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        height: 300,
        child: const Column(
          children: [
            Icon(Icons.calendar_today, size: 60, color: Colors.purple),
            SizedBox(height: 10),
            Text('Enterprise Maintenance Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Scheduled maintenance, token tax expiry, and driver shifts aligned.'),
          ],
        ),
      ),
    );
  }
}

// ==================== FLEET MANAGEMENT TAB ====================
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
    final data = await DatabaseHelper.instance.getVehicles();
    setState(() => vehicles = data);
  }

  void _showAddVehicleDialog() {
    final number = TextEditingController();
    final model = TextEditingController();
    final driver = TextEditingController();
    final phone = TextEditingController();
    final location = TextEditingController();
    String selectedType = '10-Wheeler';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Fleet Vehicle'),
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
                TextField(controller: model, decoration: const InputDecoration(labelText: 'Model/Year')),
                TextField(controller: driver, decoration: const InputDecoration(labelText: 'Driver Name')),
                TextField(controller: phone, decoration: const InputDecoration(labelText: 'Driver Phone')),
                TextField(controller: location, decoration: const InputDecoration(labelText: 'Current Location')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (number.text.isNotEmpty) {
                  await DatabaseHelper.instance.addVehicle(number.text, model.text, selectedType, driver.text, phone.text, location.text);
                  _loadVehicles();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Add Vehicle'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Vehicles'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: vehicles.isEmpty
          ? const Center(child: Text('No vehicles added.'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.directions_bus, color: Colors.white)),
                    title: Text('${v['number']} (${v['type']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Driver: ${v['driver_name']} | Loc: ${v['location']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteVehicle(v['id']);
                        _loadVehicles();
                      },
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleLedgerScreen(vehicleData: v)));
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
// ==================== DETAILED VEHICLE LEDGER ====================
class VehicleLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const VehicleLedgerScreen({super.key, required this.vehicleData});

  @override
  State<VehicleLedgerScreen> createState() => _VehicleLedgerScreenState();
}

class _VehicleLedgerScreenState extends State<VehicleLedgerScreen> {
  List<Map<String, dynamic>> records = [];
  double income = 0;
  double expense = 0;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  void _loadLedger() async {
    final data = await DatabaseHelper.instance.getRecords(widget.vehicleData['id']);
    double inc = 0;
    double exp = 0;
    for (var r in data) {
      final amt = (r['amount'] as num).toDouble();
      if (r['type'] == 'Income') {
        inc += amt;
      } else {
        exp += amt;
      }
    }
    setState(() {
      records = data;
      income = inc;
      expense = exp;
    });
  }

  void _addRecordDialog() {
    final title = TextEditingController();
    final amount = TextEditingController();
    final details = TextEditingController();
    final meter = TextEditingController();
    String type = 'Expense';
    String category = 'Oil Change';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Entry to Ledger'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: ['Income', 'Expense'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setDialogState(() => type = val!),
                ),
                DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  items: ['Trip Freight', 'Oil Change', 'Tyre/Spare Parts', 'Diesel/Fuel', 'Driver Salary', 'Toll/Challan', 'Maintenance']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title / Description')),
                TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (PKR)')),
                TextField(controller: meter, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Meter Reading (KM)')),
                TextField(controller: details, decoration: const InputDecoration(labelText: 'Notes / Vendor')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amount.text) ?? 0;
                final met = double.tryParse(meter.text) ?? 0;
                if (title.text.isNotEmpty && amt > 0) {
                  await DatabaseHelper.instance.addRecord(widget.vehicleData['id'], type, category, title.text, amt, details.text, met);
                  _loadLedger();
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
      appBar: AppBar(title: Text('${widget.vehicleData['number']} Ledger'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Income: Rs. $income', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Expense: Rs. $expense', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Net: Rs. ${income - expense}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const Center(child: Text('No Ledger Records.'))
                : ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final r = records[index];
                      final isInc = r['type'] == 'Income';
                      return ListTile(
                        leading: Icon(isInc ? Icons.arrow_downward : Icons.arrow_upward, color: isInc ? Colors.green : Colors.red),
                        title: Text('${r['title']} (${r['category']})'),
                        subtitle: Text('${r['date']} | Notes: ${r['details']}'),
                        trailing: Text('Rs. ${r['amount']}', style: TextStyle(color: isInc ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecordDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ==================== VENDORS KHATA TAB ====================
class VendorsKhataTab extends StatefulWidget {
  const VendorsKhataTab({super.key});

  @override
  State<VendorsKhataTab> createState() => _VendorsKhataTabState();
}

class _VendorsKhataTabState extends State<VendorsKhataTab> {
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

  void _addVendorDialog() {
    final name = TextEditingController();
    final shop = TextEditingController();
    final phone = TextEditingController();
    final city = TextEditingController();
    final udhar = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Shop / Vendor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Vendor Name')),
              TextField(controller: shop, decoration: const InputDecoration(labelText: 'Shop / Business Name')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: udhar, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Udhar Balance (PKR)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (name.text.isNotEmpty) {
                final bal = double.tryParse(udhar.text) ?? 0;
                await DatabaseHelper.instance.addVendor(name.text, shop.text, phone.text, city.text, bal);
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
      appBar: AppBar(title: const Text('Vendors & Shops Udhar Khata'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: vendors.isEmpty
          ? const Center(child: Text('No Vendor Khata added.'))
          : ListView.builder(
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                final v = vendors[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.store)),
                  title: Text('${v['name']} (${v['shop_name']})'),
                  subtitle: Text('${v['city']} | Ph: ${v['phone']}'),
                  trailing: Text('Rs. ${v['udhar_balance']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVendorDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ==================== ENTERPRISE CALCULATOR & TOOLS ====================
class ToolsAndCalculatorTab extends StatefulWidget {
  const ToolsAndCalculatorTab({super.key});

  @override
  State<ToolsAndCalculatorTab> createState() => _ToolsAndCalculatorTabState();
}

class _ToolsAndCalculatorTabState extends State<ToolsAndCalculatorTab> {
  final distanceController = TextEditingController();
  final mileageController = TextEditingController();
  final fuelPriceController = TextEditingController();
  double estimatedCost = 0;

  void _calculateTrip() {
    final dist = double.tryParse(distanceController.text) ?? 0;
    final avg = double.tryParse(mileageController.text) ?? 1;
    final price = double.tryParse(fuelPriceController.text) ?? 0;

    setState(() {
      estimatedCost = (dist / avg) * price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Fuel Calculator & Tools'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: distanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Trip Distance (KM)')),
            TextField(controller: mileageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Vehicle Average (KM/Litter)')),
            TextField(controller: fuelPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diesel Rate (PKR)')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calculateTrip, child: const Text('Calculate Fuel Expense')),
            const SizedBox(height: 20),
            Text('Estimated Fuel Cost: Rs. ${estimatedCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
      ),
    );
  }
}

// ==================== REMINDERS & NOTES TAB ====================
class RemindersAndNotesTab extends StatefulWidget {
  const RemindersAndNotesTab({super.key});

  @override
  State<RemindersAndNotesTab> createState() => _RemindersAndNotesTabState();
}

class _RemindersAndNotesTabState extends State<RemindersAndNotesTab> {
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() async {
    final data = await DatabaseHelper.instance.getNotes();
    setState(() => notes = data);
  }

  void _addNoteDialog() {
    final title = TextEditingController();
    final content = TextEditingController();
    bool isReminder = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Note / Maintenance Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: content, decoration: const InputDecoration(labelText: 'Content / Details')),
              CheckboxListTile(
                title: const Text('Mark as Urgent Reminder'),
                value: isReminder,
                onChanged: (val) => setDialogState(() => isReminder = val!),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (title.text.isNotEmpty) {
                  await DatabaseHelper.instance.addNote(title.text, content.text, isReminder);
                  _loadNotes();
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
      appBar: AppBar(title: const Text('Reminders & Enterprise Notes'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: notes.isEmpty
          ? const Center(child: Text('No Notes or Reminders.'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final n = notes[index];
                return ListTile(
                  leading: Icon(n['is_reminder'] == 1 ? Icons.alarm : Icons.note, color: n['is_reminder'] == 1 ? Colors.red : Colors.indigo),
                  title: Text(n['title']),
                  subtitle: Text('${n['date']} - ${n['content']}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNoteDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

