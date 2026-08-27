import 'bookings_screen.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
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
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const VehiclesScreen(),
    const DriversScreen(),
    const KhataScreen(),
    const AvgCalcScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Drivers'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Khata'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Avg Calc'),
        ],
      ),
    );
  }
}

// ---------------- HOME DASHBOARD SCREEN ----------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awan Brothers Tours & Travels', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transport Hisab ERP', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Fleet, Drivers, Khata & Udhar Manager Offline Storage System.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Management Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildDashboardCard(context, 'Vehicle Fleet', Icons.directions_bus, Colors.blue.shade100, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen()));
                }),
                _buildDashboardCard(context, 'Driver & Salary', Icons.person, Colors.orange.shade100, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriversScreen()));
                }),
                _buildDashboardCard(context, 'Udhar Khata', Icons.account_balance_wallet, Colors.green.shade100, Colors.green, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const KhataScreen()));
                }),
                _buildDashboardCard(context, 'Auto Average', Icons.calculate, Colors.purple.shade100, Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AvgCalcScreen()));
                }),
                _buildDashboardCard(context, 'Google Map / Route', Icons.map, Colors.red.shade100, Colors.red, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RouteMapScreen()));
                }),
                _buildDashboardCard(context, 'Bill & Invoices', Icons.picture_as_pdf, Colors.teal.shade100, Colors.teal, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceScreen()));
                }),
                _buildDashboardCard(context, 'Maintenance', Icons.build, Colors.amber.shade100, Colors.amber.shade900, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen()));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 26, backgroundColor: bg, child: Icon(icon, color: iconColor, size: 28)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
          ],
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
  final _regController = TextEditingController();
  final _modelController = TextEditingController();
  final _capController = TextEditingController();
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final list = await DatabaseHelper.instance.fetchAll('vehicles');
    setState(() => _vehicles = list);
  }

  Future<void> _addVehicle() async {
    if (_regController.text.isEmpty) return;
    await DatabaseHelper.instance.insertRecord('vehicles', {
      'reg_number': _regController.text,
      'model_name': _modelController.text,
      'capacity': int.tryParse(_capController.text) ?? 0,
    });
    _regController.clear();
    _modelController.clear();
    _capController.clear();
    if (mounted) Navigator.pop(context);
    _loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Fleet Management'), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: _vehicles.isEmpty
          ? const Center(child: Text('No vehicles added yet.'))
          : ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final v = _vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF1A237E), child: Icon(Icons.directions_bus, color: Colors.white)),
                    title: Text(v['reg_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Model: ${v['model_name']} | Seats: ${v['capacity']}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add New Vehicle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(controller: _regController, decoration: const InputDecoration(labelText: 'Registration No (e.g. LES-1234)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _modelController, decoration: const InputDecoration(labelText: 'Model Name (e.g. Coaster)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _capController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seat Capacity', border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _addVehicle, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white), child: const Text('Save Vehicle'))),
                ],
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  List<Map<String, dynamic>> _drivers = [];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final list = await DatabaseHelper.instance.fetchAll('drivers');
    setState(() => _drivers = list);
  }

  Future<void> _addDriver() async {
    if (_nameController.text.isEmpty) return;
    await DatabaseHelper.instance.insertRecord('drivers', {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'salary': double.tryParse(_salaryController.text) ?? 0.0,
      'advance': 0.0,
    });
    _nameController.clear();
    _phoneController.clear();
    _salaryController.clear();
    if (mounted) Navigator.pop(context);
    _loadDrivers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver & Salary Management'), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: _drivers.isEmpty
          ? const Center(child: Text('No drivers added yet.'))
          : ListView.builder(
              itemCount: _drivers.length,
              itemBuilder: (context, index) {
                final d = _drivers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Phone: ${d['phone']} | Salary: Rs. ${d['salary']}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add New Driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _salaryController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Salary (Rs.)', border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _addDriver, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white), child: const Text('Save Driver'))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- KHATA SCREEN ----------------
class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'Credit';
  List<Map<String, dynamic>> _ledger = [];

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    final list = await DatabaseHelper.instance.fetchAll('ledger');
    setState(() => _ledger = list);
  }

  Future<void> _addEntry() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;
    await DatabaseHelper.instance.insertRecord('ledger', {
      'title': _titleController.text,
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'type': _type,
      'date': DateTime.now().toString().split(' ')[0],
    });
    _titleController.clear();
    _amountController.clear();
    if (mounted) Navigator.pop(context);
    _loadLedger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Udhar & Cash Khata'), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: _ledger.isEmpty
          ? const Center(child: Text('No transactions recorded.'))
          : ListView.builder(
              itemCount: _ledger.length,
              itemBuilder: (context, index) {
                final item = _ledger[index];
                final isCredit = item['type'] == 'Credit';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCredit ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red),
                    ),
                    title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Date: ${item['date']}'),
                    trailing: Text('Rs. ${item['amount']}', style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.green : Colors.red, fontSize: 16)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => StatefulBuilder(
              builder: (context, setModalState) => Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Add Khata Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Description / Title', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs.)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Income'),
                            value: 'Credit',
                            groupValue: _type,
                            onChanged: (val) => setModalState(() => _type = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Expense'),
                            value: 'Debit',
                            groupValue: _type,
                            onChanged: (val) => setModalState(() => _type = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _addEntry, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white), child: const Text('Save Entry'))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- AVG CALC SCREEN ----------------
class AvgCalcScreen extends StatefulWidget {
  const AvgCalcScreen({super.key});

  @override
  State<AvgCalcScreen> createState() => _AvgCalcScreenState();
}

class _AvgCalcScreenState extends State<AvgCalcScreen> {
  final _kmsController = TextEditingController();
  final _fuelController = TextEditingController();
  final _priceController = TextEditingController();
  double _avgKmPerLiter = 0.0;
  double _costPerKm = 0.0;

  void _calculate() {
    final kms = double.tryParse(_kmsController.text) ?? 0.0;
    final fuel = double.tryParse(_fuelController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (kms > 0 && fuel > 0) {
      setState(() {
        _avgKmPerLiter = kms / fuel;
        _costPerKm = price > 0 ? (fuel * price) / kms : 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Average Calculator'), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _kmsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Distance Covered (KM)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _fuelController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Fuel Used (Liters)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fuel Price per Liter (Rs. Optional)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white), child: const Text('Calculate Average')),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade200)),
              child: Column(
                children: [
                  Text('Fuel Average: ${_avgKmPerLiter.toStringAsFixed(2)} KM / Liter', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const SizedBox(height: 10),
                  Text('Cost per KM: Rs. ${_costPerKm.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- ROUTE & MAP SCREEN ----------------
class RouteMapScreen extends StatelessWidget {
  const RouteMapScreen({super.key});

  Future<void> _openGoogleMapsRoute() async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=Lahore&destination=Islamabad&travelmode=driving',
    );
    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch Google Maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps / Route Tracker'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text('Lahore to Islamabad Route', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Tap below to open turn-by-turn navigation in Google Maps.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _openGoogleMapsRoute,
                icon: const Icon(Icons.navigation),
                label: const Text('Open Route in Google Maps'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, minimumSize: const Size(220, 50)),
              ),
            ],
          ),
        ),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size(200, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- MAINTENANCE & EXPENSE SCREEN ----------------
// ---------------- MAINTENANCE & EXPENSE SCREEN ----------------
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _vehicleController = TextEditingController();
  final _serviceController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    final list = await DatabaseHelper.instance.fetchAll('maintenance');
    setState(() => _records = list);
  }

  Future<void> _addRecord() async {
    if (_vehicleController.text.isEmpty || _costController.text.isEmpty) return;

    await DatabaseHelper.instance.insertRecord('maintenance', {
      'vehicleNo': _vehicleController.text,
      'serviceType': _serviceController.text.isEmpty ? 'General Maintenance' : _serviceController.text,
      'cost': double.tryParse(_costController.text) ?? 0.0,
      'date': DateTime.now().toString().split(' ')[0],
      'notes': _notesController.text,
    });

    _vehicleController.clear();
    _serviceController.clear();
    _costController.clear();
    _notesController.clear();

    if (mounted) Navigator.pop(context);
    _fetchRecords();
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Maintenance Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: _vehicleController, decoration: const InputDecoration(labelText: 'Vehicle No (e.g. LES-1234)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _serviceController, decoration: const InputDecoration(labelText: 'Service Type (Oil Change, Tires, etc.)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Cost (Rs.)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes / Remarks', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _addRecord,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                child: const Text('Save Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalExpense = _records.fold(0.0, (sum, item) => sum + (item['cost'] as double? ?? 0.0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Maintenance'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Maintenance Cost:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Rs. ${totalExpense.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              ],
            ),
          ),
          Expanded(
            child: _records.isEmpty
                ? const Center(child: Text('No maintenance records added yet.'))
                : ListView.builder(
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final item = _records[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF1A237E),
                            child: Icon(Icons.build, color: Colors.white, size: 20),
                          ),
                          title: Text('${item['vehicleNo']} - ${item['serviceType']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Date: ${item['date']}\nNotes: ${item['notes'] ?? 'N/A'}'),
                          trailing: Text('Rs. ${item['cost']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
