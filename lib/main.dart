import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';
import 'bookings_screen.dart';

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
    const BookingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Drivers'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Khata'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_add), label: 'Bookings'),
        ],
      ),
    );
  }
}

// ---------------- HOME DASHBOARD SCREEN ----------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _launchMap() async {
    final Uri url = Uri.parse('https://www.google.com/maps');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch Google Maps');
    }
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color bg,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: bg,
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
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
        title: const Text('Awan Brothers Tours & Travels'),
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
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transport Hisab ERP', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Fleet, Drivers, Khata & Party Bookings Manager', style: TextStyle(color: Colors.white70)),
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
                _buildDashboardCard(
                  context,
                  'Party Bookings',
                  Icons.bookmark_add,
                  Colors.purple.shade50,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
                ),
                _buildDashboardCard(
                  context,
                  'Vehicle Fleet',
                  Icons.directions_bus,
                  Colors.blue.shade50,
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen())),
                ),
                _buildDashboardCard(
                  context,
                  'Driver & Salary',
                  Icons.person,
                  Colors.orange.shade50,
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriversScreen())),
                ),
                _buildDashboardCard(
                  context,
                  'Udhar Khata',
                  Icons.account_balance_wallet,
                  Colors.green.shade50,
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KhataScreen())),
                ),
                _buildDashboardCard(
                  context,
                  'Auto Average',
                  Icons.calculate,
                  Colors.purple.shade50,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AverageCalcScreen())),
                ),
                _buildDashboardCard(
                  context,
                  'Google Map / Route',
                  Icons.map,
                  Colors.red.shade50,
                  Colors.red,
                  () => _launchMap(),
                ),
                _buildDashboardCard(
                  context,
                  'Bill & Invoices',
                  Icons.picture_as_pdf,
                  Colors.teal.shade50,
                  Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceScreen())),
                ),
                _buildDashboardCard(
                  context,
                  'Maintenance',
                  Icons.build,
                  Colors.deepOrange.shade50,
                  Colors.deepOrange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy Screen Placeholders
class VehiclesScreen extends StatelessWidget { const VehiclesScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Vehicles')), body: const Center(child: Text('Vehicles Screen'))); }
class DriversScreen extends StatelessWidget { const DriversScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Drivers')), body: const Center(child: Text('Drivers Screen'))); }
class KhataScreen extends StatelessWidget { const KhataScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Khata')), body: const Center(child: Text('Khata Screen'))); }
class AverageCalcScreen extends StatelessWidget { const AverageCalcScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Average Calc')), body: const Center(child: Text('Average Calc Screen'))); }
class InvoiceScreen extends StatelessWidget { const InvoiceScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Invoices')), body: const Center(child: Text('Invoice Screen'))); }
class MaintenanceScreen extends StatelessWidget { const MaintenanceScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Maintenance')), body: const Center(child: Text('Maintenance Screen'))); }
