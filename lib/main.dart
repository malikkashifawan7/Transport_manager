import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'vehicle_details_screen.dart';
import 'vendors_reminders_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportManagerApp());
}

class TransportManagerApp extends StatelessWidget {
  const TransportManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Hisab ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FleetHomeScreen(),
    BookingsScreen(),
    VendorsRemindersScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_bus), label: 'Fleet'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Vendors & Alerts'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class FleetHomeScreen extends StatefulWidget {
  const FleetHomeScreen({super.key});

  @override
  State<FleetHomeScreen> createState() => _FleetHomeScreenState();
}

class _FleetHomeScreenState extends State<FleetHomeScreen> {
  List<Map<String, dynamic>> vehicles = [];

  @override
  void initState() {
    super.initState();
    _refreshFleet();
  }

  void _refreshFleet() async {
    final data = await DatabaseHelper.instance.getVehicles();
    setState(() => vehicles = data);
  }

  void _openAddVehicleDialog([Map<String, dynamic>? v]) {
    final numberCtrl = TextEditingController(text: v?['number'] ?? '');
    final typeCtrl = TextEditingController(text: v?['type'] ?? '10-Wheeler');
    final modelCtrl = TextEditingController(text: v?['model'] ?? '');
    final driverCtrl = TextEditingController(text: v?['driver_name'] ?? '');
    final phoneCtrl = TextEditingController(text: v?['driver_phone'] ?? '');
    final cnicCtrl = TextEditingController(text: v?['driver_cnic'] ?? '');
    final locCtrl = TextEditingController(text: v?['location'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (dialogCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v == null ? 'Add Enterprise Vehicle' : 'Edit Vehicle',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number (e.g. LES-1234)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Vehicle Type', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model / Year', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Driver Phone', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: cnicCtrl, decoration: const InputDecoration(labelText: 'Driver CNIC', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Base Location', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (numberCtrl.text.isNotEmpty) {
                      final payload = {
                        'number': numberCtrl.text,
                        'type': typeCtrl.text,
                        'model': modelCtrl.text,
                        'driver_name': driverCtrl.text,
                        'driver_phone': phoneCtrl.text,
                        'driver_cnic': cnicCtrl.text,
                        'location': locCtrl.text,
                      };
                      try {
                        if (v == null) {
                          await DatabaseHelper.instance.addVehicle(payload);
                        } else {
                          await DatabaseHelper.instance.updateVehicle(v['id'], payload);
                        }
                        _refreshFleet();
                        if (mounted) Navigator.pop(dialogCtx);
                      } catch (e) {
                        debugPrint('Error saving vehicle: $e');
                      }
                    }
                  },
                  child: const Text('Save Vehicle'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Management ERP'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: vehicles.isEmpty
          ? const Center(child: Text('No Vehicles in Fleet. Tap + to add.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: vehicles.length,
              itemBuilder: (context, idx) {
                final item = vehicles[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['number'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Chip(label: Text(item['type'] ?? 'Truck'), backgroundColor: Colors.blue.shade50),
                          ],
                        ),
                        Text('Driver: ${item['driver_name']} (${item['driver_phone']})'),
                        Text('Location: ${item['location']} | CNIC: ${item['driver_cnic']}'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openAddVehicleDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteVehicle(item['id']);
                                _refreshFleet();
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.analytics),
                              label: const Text('Details & Ledger'),
                              onPressed: () async {
                                final recs = await DatabaseHelper.instance.getRecords(item['id']);
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VehicleDetailsScreen(vehicle: item, records: recs),
                                    ),
                                  );
                                }
                              },
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        onPressed: () => _openAddVehicleDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
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

  void _openAddBookingDialog() {
    final vehicleCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add New Trip Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client Name')),
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route (e.g. LHR to KHI)')),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (PKR)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (clientCtrl.text.isNotEmpty) {
                await DatabaseHelper.instance.addBooking({
                  'vehicle_number': vehicleCtrl.text,
                  'client': clientCtrl.text,
                  'route': routeCtrl.text,
                  'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                  'date': DateTime.now().toString().split(' ')[0],
                });
                _loadBookings();
                if (mounted) Navigator.pop(dialogCtx);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Bookings'), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: bookings.isEmpty
          ? const Center(child: Text('No Active Bookings'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bookings.length,
              itemBuilder: (context, i) {
                final item = bookings[i];
                return Card(
                  child: ListTile(
                    title: Text('${item['vehicle_number']} • ${item['client']}'),
                    subtitle: Text('Route: ${item['route']} | Date: ${item['date']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('PKR ${item['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper.instance.deleteBooking(item['id']);
                            _loadBookings();
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        onPressed: _openAddBookingDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Settings'), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: const Center(child: Text('Enterprise ERP Configuration v3.0')),
    );
  }
}
