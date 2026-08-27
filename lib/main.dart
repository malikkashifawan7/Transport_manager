import 'auto_average_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'vehicles_screen.dart';
import 'bookings_screen.dart';
import 'drivers_screen.dart';

void main() {
  runApp(const TransportApp());
}

class TransportApp extends StatelessWidget {
  const TransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Awan Brothers Tours & Travels',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A237E),
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        useMaterial3: true,
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
    const HomeDashboardView(),
    const VehiclesScreen(),
    const DriversScreen(),
    const VehiclesScreen(), // Udhar Khata is integrated inside Vehicle Detail View
    const BookingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awan Brothers Tours & Travels', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Management Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildCard(context, 'Party Bookings', Icons.bookmark_add, Colors.purple.shade50, Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen()));
                }),
                _buildCard(context, 'Vehicle Fleet', Icons.directions_bus, Colors.blue.shade50, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen()));
                }),
                _buildCard(context, 'Driver & Salary', Icons.person, Colors.orange.shade50, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriversScreen()));
                }),
                _buildCard(context, 'Udhar Khata', Icons.account_balance_wallet, Colors.green.shade50, Colors.green, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen()));
                }),
                _buildCard(context, 'Auto Average', Icons.calculate, Colors.purple.shade50, Colors.purple.shade400, () {}),
                _buildCard(context, 'Google Map / Route', Icons.map, Colors.red.shade50, Colors.red.shade400, () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: bgColor,
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
