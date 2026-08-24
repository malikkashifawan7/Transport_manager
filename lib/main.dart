import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'vehicle_details_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportERPApp());
}

class TransportERPApp extends StatelessWidget {
  const TransportERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EUI Elite Pro Transport ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFF2563EB),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FleetDashboardScreen(),
    const GlobalAnalyticsAndLedgerScreen(),
    const AdvanceBookingsScreen(),
    const DirectoryAndNotesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_bus_rounded), label: 'Fleet Hub'),
          NavigationDestination(icon: Icon(Icons.analytics_rounded), label: 'Total Ledger'),
          NavigationDestination(icon: Icon(Icons.book_online_rounded), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.folder_shared_rounded), label: 'Directory/Notes'),
        ],
      ),
    );
  }
}

// 1. Upgraded Fleet Dashboard Screen
class FleetDashboardScreen extends StatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  State<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends State<FleetDashboardScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _allRecords = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    final vData = await DatabaseHelper.instance.getVehicles();
    final rData = await DatabaseHelper.instance.getRecords(null);
    setState(() {
      _vehicles = vData;
      _allRecords = rData;
    });
  }

  double get totalIncome => _allRecords
      .where((r) => r['type'] == 'Income')
      .fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  double get totalExpense => _allRecords
      .where((r) => r['type'] == 'Expense')
      .fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  List<Map<String, dynamic>> get _filteredVehicles {
    if (_searchQuery.isEmpty) return _vehicles;
    return _vehicles.where((v) {
      final num = (v['number'] ?? '').toString().toLowerCase();
      final driver = (v['driver_name'] ?? '').toString().toLowerCase();
      return num.contains(_searchQuery.toLowerCase()) || driver.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openAddVehicleDialog() {
    final numCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String type = 'Truck / Trailer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Fleet Vehicle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Reg Number (e.g. LES-786)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                onPressed: () async {
                  if (numCtrl.text.isNotEmpty) {
                    await DatabaseHelper.instance.addVehicle({
                      'number': numCtrl.text,
                      'driver_name': driverCtrl.text,
                      'driver_phone': phoneCtrl.text,
                      'type': type,
                    });
                    _loadDashboardData();
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('SAVE VEHICLE'),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Operations Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDashboardData),
        ],
      ),
      body: Column(
        children: [
          // Elite Pro Analytics Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('ACTIVE UNITS', '${_vehicles.length}', Colors.blueAccent)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('TOTAL REVENUE', 'PKR ${totalIncome.toStringAsFixed(0)}', Colors.greenAccent)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('NET PROFIT', 'PKR ${netProfit.toStringAsFixed(0)}', netProfit >= 0 ? Colors.greenAccent : Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by Vehicle No or Driver...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white12,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),

          // Vehicle List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredVehicles.length,
              itemBuilder: (context, index) {
                final v = _filteredVehicles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF0F172A), size: 28),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(v['number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                          child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Driver: ${v['driver_name']} | Contact: ${v['driver_phone']}'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteVehicle(v['id']);
                        _loadDashboardData();
                      },
                    ),
                    onTap: () async {
                      final records = await DatabaseHelper.instance.getRecords(v['id']);
                      if (context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailsScreen(vehicle: v, records: records))).then((_) => _loadDashboardData());
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: _openAddVehicleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
// 2. Global Consolidated Ledger
class GlobalAnalyticsAndLedgerScreen extends StatefulWidget {
  const GlobalAnalyticsAndLedgerScreen({super.key});

  @override
  State<GlobalAnalyticsAndLedgerScreen> createState() => _GlobalAnalyticsAndLedgerScreenState();
}

class _GlobalAnalyticsAndLedgerScreenState extends State<GlobalAnalyticsAndLedgerScreen> {
  List<Map<String, dynamic>> _allRecords = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() async {
    final data = await DatabaseHelper.instance.getRecords(null);
    setState(() => _allRecords = data);
  }

  double get totalFleetIncome => _allRecords.where((r) => r['type'] == 'Income').fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());
  double get totalFleetExpense => _allRecords.where((r) => r['type'] == 'Expense').fold(0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());

  @override
  Widget build(BuildContext context) {
    final netProfit = totalFleetIncome - totalFleetExpense;

    return Scaffold(
      appBar: AppBar(title: const Text('Overall Fleet Ledger'), backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCard('Total Revenue', 'PKR ${totalFleetIncome.toStringAsFixed(0)}', Colors.greenAccent),
                _buildCard('Total Expense', 'PKR ${totalFleetExpense.toStringAsFixed(0)}', Colors.redAccent),
                _buildCard('Net Profit/Loss', 'PKR ${netProfit.toStringAsFixed(0)}', netProfit >= 0 ? Colors.greenAccent : Colors.redAccent),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _allRecords.length,
              itemBuilder: (context, index) {
                final item = _allRecords[index];
                final isIncome = item['type'] == 'Income';
                return Card(
                  child: ListTile(
                    title: Text(item['title'] ?? item['sub_category']),
                    subtitle: Text('${item['date']} • Party: ${item['party_name'] ?? "Direct"}'),
                    trailing: Text(
                      '${isIncome ? "+" : "-"} PKR ${item['amount']}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

// 3. Advance Bookings System
class AdvanceBookingsScreen extends StatefulWidget {
  const AdvanceBookingsScreen({super.key});

  @override
  State<AdvanceBookingsScreen> createState() => _AdvanceBookingsScreenState();
}

class _AdvanceBookingsScreenState extends State<AdvanceBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() async {
    final data = await DatabaseHelper.instance.getBookings();
    setState(() => _bookings = data);
  }

  void _addBookingDialog() {
    final clientCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final advanceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New Trip Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route (e.g. LHR to KHI)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Freight (PKR)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: advanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance Received (PKR)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.instance.addBooking({
                  'client': clientCtrl.text,
                  'route': routeCtrl.text,
                  'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                  'advance': double.tryParse(advanceCtrl.text) ?? 0.0,
                  'date': DateTime.now().toString().split(' ')[0],
                });
                _loadBookings();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('CREATE BOOKING'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advance Trip Bookings'), backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final b = _bookings[index];
          return Card(
            child: ListTile(
              title: Text('${b['client']} - ${b['route']}'),
              subtitle: Text('Date: ${b['date']} | Total: PKR ${b['amount']}'),
              trailing: Text('Advance: PKR ${b['advance']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: _addBookingDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 4. Directory & Notepad
class DirectoryAndNotesScreen extends StatefulWidget {
  const DirectoryAndNotesScreen({super.key});

  @override
  State<DirectoryAndNotesScreen> createState() => _DirectoryAndNotesScreenState();
}

class _DirectoryAndNotesScreenState extends State<DirectoryAndNotesScreen> {
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() async {
    final data = await DatabaseHelper.instance.getNotes();
    setState(() => _notes = data);
  }

  void _addNoteDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Memo / Reminder Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Details / Note', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.instance.addNote({
                  'title': titleCtrl.text,
                  'content': contentCtrl.text,
                  'date': DateTime.now().toString().split(' ')[0],
                });
                _loadNotes();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('SAVE NOTE'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enterprise Notepad & Reminders'), backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final n = _notes[index];
          return Card(
            child: ListTile(
              title: Text(n['title'] ?? 'Note'),
              subtitle: Text(n['content'] ?? ''),
              trailing: Text(n['date'] ?? ''),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: _addNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

