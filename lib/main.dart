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
      title: 'Transport Hisab Pro Plus Enterprise',
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
    _database = await _initDB('transport_hisab_v8.db');
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
        driver_cnic TEXT,
        location TEXT,
        status TEXT DEFAULT 'Active'
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

  Future<List<Map<String, dynamic>>> getRecords(int? vehicleId, String? month) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> args = [];

    if (vehicleId != null) {
      whereClause += 'vehicle_id = ?';
      args.add(vehicleId);
    }

    if (month != null && month.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date LIKE ?';
      args.add('$month%');
    }

    return await db.query(
      'records',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getVendors() async {
    final db = await instance.database;
    return await db.query('vendors', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final db = await instance.database;
    return await db.query('reminders', orderBy: 'due_date ASC');
  }

  Future<int> addVehicle(String number, String model, String type, String driver, String phone, String cnic, String loc) async {
    final db = await instance.database;
    return await db.insert('vehicles', {
      'number': number,
      'model': model,
      'type': type,
      'driver_name': driver,
      'driver_phone': phone,
      'driver_cnic': cnic,
      'location': loc,
      'status': 'Active',
    });
  }

  Future<int> addRecord(int vId, String type, String mainCat, String subCat, String title, double amt, String details, double meter) async {
    final db = await instance.database;
    return await db.insert('records', {
      'vehicle_id': vId,
      'type': type,
      'main_category': mainCat,
      'sub_category': subCat,
      'title': title,
      'amount': amt,
      'details': details,
      'meter_reading': meter,
      'date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  Future<int> addVendor(String name, String shop, String phone, String address, String city, double balance) async {
    final db = await instance.database;
    return await db.insert('vendors', {
      'name': name,
      'shop_name': shop,
      'phone': phone,
      'address': address,
      'city': city,
      'udhar_balance': balance,
    });
  }

  Future<int> addReminder(String title, String dueDate, String type, String details) async {
    final db = await instance.database;
    return await db.insert('reminders', {
      'title': title,
      'due_date': dueDate,
      'type': type,
      'details': details,
    });
  }
}

// ==================== MAIN SHELL ====================
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
    const DirectoryAndVendorsTab(),
    const RemindersTab(),
    const UserManualHelpTab(),
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
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus_rounded), label: 'Fleet & Profit'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_rounded), label: 'Directory'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm_rounded), label: 'Reminders'),
          BottomNavigationBarItem(icon: Icon(Icons.help_center_rounded), label: 'Help / Manual'),
        ],
      ),
    );
  }
}

// ==================== DASHBOARD TAB ====================
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
    final r = await DatabaseHelper.instance.getRecords(null, null);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Universal Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Vehicle Number or Driver...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
            const SizedBox(height: 16),

            // Overall Summary Card
            Card(
              elevation: 4,
              color: Colors.indigo.shade900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Total Enterprise Financial Overview', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          const Text('Total Freight', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                          Text('Rs. ${totalIncome.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                        Column(children: [
                          const Text('Total Expense', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          Text('Rs. ${totalExpense.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                        Column(children: [
                          const Text('Net Balance', style: TextStyle(color: Colors.white, fontSize: 12)),
                          Text('Rs. ${(totalIncome - totalExpense).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Fleet Overview & Live Quick Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredVehicles.length,
              itemBuilder: (context, index) {
                final v = filteredVehicles[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.directions_bus, color: Colors.white)),
                    title: Text('${v['number']} (${v['type']})', style: const TextStyle(fontWeight: FontWeight.bold)),
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
// ==================== FLEET & PROFIT BARS TAB ====================
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Profit / Loss Performance'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final v = vehicles[index];
          return VehicleProfitBarCard(vehicle: v);
        },
      ),
    );
  }
}

class VehicleProfitBarCard extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleProfitBarCard({super.key, required this.vehicle});

  @override
  State<VehicleProfitBarCard> createState() => _VehicleProfitBarCardState();
}

class _VehicleProfitBarCardState extends State<VehicleProfitBarCard> {
  double income = 0;
  double expense = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    final recs = await DatabaseHelper.instance.getRecords(widget.vehicle['id'], null);
    double inc = 0;
    double exp = 0;
    for (var r in recs) {
      double amt = (r['amount'] as num).toDouble();
      if (r['type'] == 'Income') {
        inc += amt;
      } else {
        exp += amt;
      }
    }
    setState(() {
      income = inc;
      expense = exp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    final total = income + expense;
    final incomeRatio = total == 0 ? 0.5 : (income / total);

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
                Text(widget.vehicle['number'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  net >= 0 ? '+ Rs. ${net.toStringAsFixed(0)} (Profit)' : '- Rs. ${net.abs().toStringAsFixed(0)} (Loss)',
                  style: TextStyle(color: net >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Driver: ${widget.vehicle['driver_name']} | ${widget.vehicle['type']}'),
            const SizedBox(height: 10),

            // Visual Profit/Loss Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: incomeRatio,
                minHeight: 12,
                backgroundColor: Colors.red.shade300,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Income: Rs. ${income.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('Expense: Rs. ${expense.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: const Text('Open Detailed Ledger'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => IndividualLedgerScreen(vehicle: widget.vehicle)));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==================== INDIVIDUAL / MONTHLY LEDGER WITH SUB-CATEGORIES ====================
class IndividualLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const IndividualLedgerScreen({super.key, required this.vehicle});

  @override
  State<IndividualLedgerScreen> createState() => _IndividualLedgerScreenState();
}

class _IndividualLedgerScreenState extends State<IndividualLedgerScreen> {
  List<Map<String, dynamic>> records = [];
  String selectedMonth = ''; // Format: YYYY-MM

  final Map<String, List<String>> categoriesWithSub = {
    'Fuel': ['Diesel filling', 'AdBlue/Def', 'Generator Diesel'],
    'Maintenance': ['Mobil Oil / Oil Change', 'Filter Replacement', 'Greasing & Washing', 'Brake / Clutch Repair'],
    'Spare Parts & Tyres': ['New Tyre Purchase', 'Tyre Re-treading / Resole', 'Puncture Repair', 'Engine / Gear Parts'],
    'Driver & Staff': ['Driver Advance', 'Driver Food / Bhatta', 'Cleaner Salary', 'Trip Bonus'],
    'Toll & Legal': ['Motorway Toll Tax', 'Challan / Penalty', 'Token Tax / Fitness', 'Document Renewal'],
  };

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  void _loadLedger() async {
    final data = await DatabaseHelper.instance.getRecords(widget.vehicle['id'], selectedMonth);
    setState(() => records = data);
  }

  void _addEntryDialog() {
    final title = TextEditingController();
    final amount = TextEditingController();
    final details = TextEditingController();
    final meter = TextEditingController();

    String type = 'Expense';
    String mainCat = 'Fuel';
    String subCat = categoriesWithSub['Fuel']![0];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Sub-Category Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: ['Income', 'Expense'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                DropdownButton<String>(
                  value: mainCat,
                  isExpanded: true,
                  items: categoriesWithSub.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      mainCat = v!;
                      subCat = categoriesWithSub[mainCat]![0];
                    });
                  },
                ),
                DropdownButton<String>(
                  value: subCat,
                  isExpanded: true,
                  items: categoriesWithSub[mainCat]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => subCat = v!),
                ),
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title / Party Name')),
                TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (PKR)')),
                TextField(controller: meter, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Meter Reading (KM)')),
                TextField(controller: details, decoration: const InputDecoration(labelText: 'Vendor / Notes')),
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
                  await DatabaseHelper.instance.addRecord(
                    widget.vehicle['id'],
                    type,
                    mainCat,
                    subCat,
                    title.text,
                    amt,
                    details.text,
                    met,
                  );
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
      appBar: AppBar(
        title: Text('${widget.vehicle['number']} Ledger'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Monthly Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'e.g. 2026-08 (Leave empty for all)'),
                    onChanged: (v) {
                      selectedMonth = v.trim();
                      _loadLedger();
                    },
                  ),
                ),
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
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: ListTile(
                    leading: Icon(isInc ? Icons.arrow_circle_down : Icons.arrow_circle_up, color: isInc ? Colors.green : Colors.red),
                    title: Text('${r['title']} [${r['sub_category']}]'),
                    subtitle: Text('${r['date']} | ${r['main_category']} | Meter: ${r['meter_reading']} KM'),
                    trailing: Text('Rs. ${r['amount']}', style: TextStyle(color: isInc ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntryDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ==================== PHONE DIRECTORY & VENDORS KHATA ====================
class DirectoryAndVendorsTab extends StatefulWidget {
  const DirectoryAndVendorsTab({super.key});

  @override
  State<DirectoryAndVendorsTab> createState() => _DirectoryAndVendorsTabState();
}

class _DirectoryAndVendorsTabState extends State<DirectoryAndVendorsTab> {
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
    final address = TextEditingController();
    final city = TextEditingController();
    final balance = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Phone / Vendor Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name (e.g. Mechanic / Spare Parts)')),
              TextField(controller: shop, decoration: const InputDecoration(labelText: 'Shop / Company Name')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone Number')),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: balance, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Udhar Balance (PKR)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (name.text.isNotEmpty) {
                final b = double.tryParse(balance.text) ?? 0;
                await DatabaseHelper.instance.addVendor(name.text, shop.text, phone.text, address.text, city.text, b);
                _loadVendors();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save Contact'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Directory & Vendors Khata'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: ListView.builder(
        itemCount: vendors.length,
        itemBuilder: (context, index) {
          final v = vendors[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('${v['name']} (${v['shop_name']})'),
              subtitle: Text('${v['phone']} | ${v['address']}, ${v['city']}'),
              trailing: Text('Bal: Rs. ${v['udhar_balance']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVendorDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

// ==================== REMINDERS TAB ====================
class RemindersTab extends StatefulWidget {
  const RemindersTab({super.key});

  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab> {
  List<Map<String, dynamic>> reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() async {
    final r = await DatabaseHelper.instance.getReminders();
    setState(() => reminders = r);
  }

  void _addReminderDialog() {
    final title = TextEditingController();
    final date = TextEditingController();
    final details = TextEditingController();
    String type = 'Oil Change';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Maintenance Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: type,
                isExpanded: true,
                items: ['Oil Change', 'Token Tax', 'Fitness Certificate', 'Insurance Renewal', 'Tyre Change']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Vehicle Number / Title')),
              TextField(controller: date, decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)')),
              TextField(controller: details, decoration: const InputDecoration(labelText: 'Details')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (title.text.isNotEmpty) {
                  await DatabaseHelper.instance.addReminder(title.text, date.text, type, details.text);
                  _loadReminders();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save Reminder'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Reminders'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: ListView.builder(
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final r = reminders[index];
          return ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.orange),
            title: Text('${r['title']} [${r['type']}]'),
            subtitle: Text('Due Date: ${r['due_date']} | Notes: ${r['details']}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminderDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add_alert, color: Colors.white),
      ),
    );
  }
}

// ==================== USER MANUAL & HELP TAB ====================
class UserManualHelpTab extends StatelessWidget {
  const UserManualHelpTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Manual & Help System'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Urdu Guidance (اردو)'),
              Tab(text: 'English Guide'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UrduManualView(),
            EnglishManualView(),
          ],
        ),
      ),
    );
  }
}

class UrduManualView extends StatelessWidget {
  const UrduManualView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('ٹرانسپورٹ حساب پرو - استعمال کرنے کا طریقہ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
          SizedBox(height: 12),
          Text('1. نئی گاڑی شامل کرنا:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Fleet Tab میں جا کر + کا بٹن دبائیں، گاڑی کا نمبر، ڈرائیور کا نام اور موبائل نمبر درج کریں۔'),
          SizedBox(height: 12),
          Text('2. گاڑی کا لیجر اور حساب:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('ہر گاڑی کے نیچے "Open Detailed Ledger" کا بٹن ہے۔ وہاں ڈیزل، مرمت، اور فرائیٹ کا مکمل حساب درج کریں۔'),
          SizedBox(height: 12),
          Text('3. نوٹیفکیشن اور آئل چینج:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Reminders Tab میں آئل چینج اور ٹوکن ٹیکس کی آخری تاریخ درج کریں تاکہ وقت پر یاد دہانی ہو۔'),
        ],
      ),
    );
  }
}

class EnglishManualView extends StatelessWidget {
  const EnglishManualView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('T
