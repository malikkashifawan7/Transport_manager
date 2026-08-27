import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const TransportApp());
}

class TransportApp extends StatelessWidget {
  const TransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Hisab ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: Colors.orangeAccent,
        ),
      ),
      home: const MainNavigationHub(),
    );
  }
}

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(onNavigate: (index) => setState(() => _selectedIndex = index)),
      const VehiclesScreen(),
      const DriversScreen(),
      const LedgerKhataScreen(),
      const AutoAverageScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Awan Brothers Tours & Travels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.directions_bus), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Drivers'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Khata'),
          NavigationDestination(icon: Icon(Icons.calculate), label: 'Avg Calc'),
        ],
      ),
    );
  }
}

// ---------------- DASHBOARD HOME SCREEN ----------------
class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: const Color(0xFF1A237E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transport Hisab ERP', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Fleet, Drivers, Khata & Udhar Manager Offline Storage System.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Management Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: [
              _buildFeatureCard(context, Icons.directions_bus, 'Vehicle Fleet', Colors.blue, () => onNavigate(1)),
              _buildFeatureCard(context, Icons.person, 'Driver & Salary', Colors.orange, () => onNavigate(2)),
              _buildFeatureCard(context, Icons.account_balance_wallet, 'Udhar Khata', Colors.green, () => onNavigate(3)),
              _buildFeatureCard(context, Icons.calculate, 'Auto Average', Colors.purple, () => onNavigate(4)),
              _buildFeatureCard(context, Icons.map, 'Google Map / Route', Colors.redAccent, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RouteMapScreen()));
              }),
              _buildFeatureCard(context, Icons.picture_as_pdf, 'Bill & Invoices', Colors.teal, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const InvoiceScreen()));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- VEHICLES SCREEN ----------------
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _refreshVehicles();
  }

  void _refreshVehicles() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('vehicles');
    setState(() => _vehicles = data);
  }

  void _addVehicleDialog() {
    final regController = TextEditingController();
    final modelController = TextEditingController();
    final capacityController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: regController, decoration: const InputDecoration(labelText: 'Reg Number (e.g. LES-1234)')),
            TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Model / Bus Type')),
            TextField(controller: capacityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity (Seats)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (regController.text.isNotEmpty) {
                final db = await DatabaseHelper.instance.database;
                await db.insert('vehicles', {
                  'reg_number': regController.text,
                  'model_name': modelController.text.isEmpty ? 'Standard Bus' : modelController.text,
                  'capacity': int.tryParse(capacityController.text) ?? 50,
                });
                Navigator.pop(ctx);
                _refreshVehicles();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addVehicleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
      body: _vehicles.isEmpty
          ? const Center(child: Text('No vehicles added. Click + to add.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vehicles.length,
              itemBuilder: (ctx, idx) {
                final v = _vehicles[idx];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
                    title: Text('${v['model_name']} - ${v['reg_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Capacity: ${v['capacity']} Seats'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final db = await DatabaseHelper.instance.database;
                        await db.delete('vehicles', where: 'id = ?', whereArgs: [v['id']]);
                        _refreshVehicles();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- DRIVERS SCREEN ----------------
class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  List<Map<String, dynamic>> _drivers = [];

  @override
  void initState() {
    super.initState();
    _refreshDrivers();
  }

  void _refreshDrivers() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('drivers');
    setState(() => _drivers = data);
  }

  void _addDriverDialog() {
    final nameController = TextEditingController();
    final salaryController = TextEditingController();
    final advanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Driver Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: salaryController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Salary')),
            TextField(controller: advanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance Paid')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final db = await DatabaseHelper.instance.database;
                await db.insert('drivers', {
                  'name': nameController.text,
                  'salary': double.tryParse(salaryController.text) ?? 0.0,
                  'advance': double.tryParse(advanceController.text) ?? 0.0,
                });
                Navigator.pop(ctx);
                _refreshDrivers();
              }
            },
            child: const Text('Save Driver'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDriverDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Driver'),
      ),
      body: _drivers.isEmpty
          ? const Center(child: Text('No Driver Records Found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _drivers.length,
              itemBuilder: (ctx, idx) {
                final d = _drivers[idx];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Salary: Rs. ${d['salary']} | Advance: Rs. ${d['advance']}'),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- UDHAR KHATA SCREEN ----------------
class LedgerKhataScreen extends StatefulWidget {
  const LedgerKhataScreen({super.key});

  @override
  State<LedgerKhataScreen> createState() => _LedgerKhataScreenState();
}

class _LedgerKhataScreenState extends State<LedgerKhataScreen> {
  List<Map<String, dynamic>> _ledger = [];

  @override
  void initState() {
    super.initState();
    _refreshLedger();
  }

  void _refreshLedger() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('ledger');
    setState(() => _ledger = data);
  }

  void _addKhataEntryDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Khata Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Description / Customer')),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final db = await DatabaseHelper.instance.database;
                await db.insert('ledger', {
                  'title': titleController.text,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'type': 'Credit',
                  'date': DateTime.now().toString().split(' ')[0],
                });
                Navigator.pop(ctx);
                _refreshLedger();
              }
            },
            child: const Text('Add Entry'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addKhataEntryDialog,
        icon: const Icon(Icons.add_card),
        label: const Text('Add Khata'),
      ),
      body: _ledger.isEmpty
          ? const Center(child: Text('No Khata Entries Saved.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ledger.length,
              itemBuilder: (ctx, idx) {
                final item = _ledger[idx];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.receipt, color: Colors.white)),
                    title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Date: ${item['date']}'),
                    trailing: Text('Rs. ${item['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- AUTO AVERAGE CALCULATOR ----------------
class AutoAverageScreen extends StatefulWidget {
  const AutoAverageScreen({super.key});

  @override
  State<AutoAverageScreen> createState() => _AutoAverageScreenState();
}

class _AutoAverageScreenState extends State<AutoAverageScreen> {
  final kmController = TextEditingController();
  final fuelController = TextEditingController();
  double? averageResult;

  void calculateAverage() {
    final km = double.tryParse(kmController.text) ?? 0;
    final fuel = double.tryParse(fuelController.text) ?? 0;
    if (km > 0 && fuel > 0) {
      setState(() {
        averageResult = km / fuel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('Fuel Average Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: kmController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Distance Traveled (KM)', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: fuelController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Fuel Consumed (Liters)', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: calculateAverage,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
            child: const Text('Calculate Average (KM/L)'),
          ),
          if (averageResult != null) ...[
            const SizedBox(height: 30),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Vehicle Average: ${averageResult!.toStringAsFixed(2)} KM/L', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            )
          ]
        ],
      ),
    );
  }
}

// ---------------- BILL & INVOICE GENERATOR SCREEN ----------------
class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  void _generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Awan Brothers Tours & Travels', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Booking Receipt / Official Invoice', style: const pw.TextStyle(fontSize: 16)),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Customer Name: Valued Client'),
              pw.Text('Route: Lahore to Islamabad'),
              pw.Text('Total Amount: Rs. 45,000'),
              pw.Text('Advance Paid: Rs. 15,000'),
              pw.Text('Remaining Balance: Rs. 30,000'),
              pw.SizedBox(height: 30),
              pw.Text('Thank you for choosing Awan Brothers Tours!'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice & PDF Generator'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              const Text('Generate & Print Official Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _generatePdf(context),
                icon: const Icon(Icons.print),
                label: const Text('Print / Share PDF Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- ROUTE & MAP SCREEN ----------------
class RouteMapScreen extends StatelessWidget {
  const RouteMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps / Route Tracker'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.redAccent),
            SizedBox(height: 20),
            Text(
              'Google Maps & Route System Linked',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Ready for GPS & Distance tracking integration.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
