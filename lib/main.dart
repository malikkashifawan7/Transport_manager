import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pdf_export_service.dart';
import 'excel_export_service.dart';
import 'vehicle_details_screen.dart';
import 'vendors_reminders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportManagerApp());
}

class TransportManagerApp extends StatefulWidget {
  const TransportManagerApp({super.key});

  @override
  State<TransportManagerApp> createState() => _TransportManagerAppState();
}

class _TransportManagerAppState extends State<TransportManagerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport Manager',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: MainTabNavigation(onThemeChanged: _toggleTheme),
    );
  }
}

class MainTabNavigation extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const MainTabNavigation({super.key, required this.onThemeChanged});

  @override
  State<MainTabNavigation> createState() => _MainTabNavigationState();
}

class _MainTabNavigationState extends State<MainTabNavigation> {
  int _currentIndex = 0;
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      const FleetScreenTab(),
      const BookingsTab(),
      const VendorsRemindersScreen(),
      SettingsTab(
        isDarkMode: isDarkMode,
        onThemeChanged: (val) {
          setState(() => isDarkMode = val);
          widget.onThemeChanged(val);
        },
      ),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Vendors & Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
// ==================== FLEET TAB ====================
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
                return VehicleCard(
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

class VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VehicleCard({super.key, required this.vehicle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
                Text('${vehicle['number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: onEdit),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
                  ],
                )
              ],
            ),
            Text('Driver: ${vehicle['driver_name'] ?? 'N/A'} (${vehicle['driver_phone'] ?? ''})'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Map & Status'),
                  onPressed: () async {
                    final recs = await DatabaseHelper.instance.getRecords(vehicle['id']);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VehicleDetailsScreen(vehicle: vehicle, records: recs),
                        ),
                      );
                    }
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Ledger'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => IndividualLedgerScreen(vehicle: vehicle)));
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
// ==================== LEDGER SCREEN ====================
class IndividualLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const IndividualLedgerScreen({super.key, required this.vehicle});

  @override
  State<IndividualLedgerScreen> createState() => _IndividualLedgerScreenState();
}

class _IndividualLedgerScreenState extends State<IndividualLedgerScreen> {
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  void _loadLedger() async {
    final data = await DatabaseHelper.instance.getRecords(widget.vehicle['id']);
    setState(() => records = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle['number']} Ledger'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export Excel',
            onPressed: () => ExcelExportService.exportLedgerToExcel(widget.vehicle['number'], records),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print PDF',
            onPressed: () => PdfReportService.generateAndPrintVehicleLedger(widget.vehicle, records),
          ),
        ],
      ),
      body: records.isEmpty
          ? const Center(child: Text('No transactions.'))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final r = records[index];
                final isInc = r['type'] == 'Income';
                return ListTile(
                  leading: Icon(isInc ? Icons.arrow_downward : Icons.arrow_upward, color: isInc ? Colors.green : Colors.red),
                  title: Text('${r['title']} [${r['sub_category']}]'),
                  subtitle: Text('${r['date']}'),
                  trailing: Text('Rs. ${r['amount']}', style: TextStyle(color: isInc ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                );
              },
            ),
    );
  }
}

// ==================== BOOKINGS TAB ====================
class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() async {
    final b = await DatabaseHelper.instance.getBookings(null);
    setState(() => bookings = b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: bookings.isEmpty
          ? const Center(child: Text('No Active Bookings'))
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                return ListTile(
                  title: Text(b['party_name'] ?? 'Booking'),
                  subtitle: Text('${b['route_from']} ➔ ${b['route_to']}'),
                );
              },
            ),
    );
  }
}

// ==================== SETTINGS TAB ====================
class SettingsTab extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsTab({super.key, required this.isDarkMode, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Theme'),
            subtitle: const Text('Enable dark mode UI'),
            value: isDarkMode,
            onChanged: onThemeChanged,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.system_update),
            title: Text('Auto Update Check'),
            subtitle: Text('App is up to date (Version 1.0.0)'),
          ),
        ],
      ),
    );
  }
}
