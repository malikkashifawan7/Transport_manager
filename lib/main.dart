import 'package:flutter/material.dart';

import 'vehicles_screen.dart';
import 'drivers_screen.dart';
import 'bookings_screen.dart';
import 'vendors_reminders_screen.dart';
import 'screens/fuel_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AdminDashboardView(onNavigate: _onItemTapped),
      const VehiclesScreen(),
      const DriversScreen(),
      const FuelScreen(),
      const BookingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Vehicles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Drivers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'Fuel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }
}

class AdminDashboardView extends StatelessWidget {
  final Function(int) onNavigate;

  const AdminDashboardView({Key? key, required this.onNavigate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awan Brothers Tours & Travels'),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Management Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildCard(
                  context,
                  Icons.bookmark_add,
                  'Party Bookings',
                  Colors.purple,
                  () => onNavigate(4),
                ),
                _buildCard(
                  context,
                  Icons.directions_bus,
                  'Vehicle Fleet',
                  Colors.blue,
                  () => onNavigate(1),
                ),
                _buildCard(
                  context,
                  Icons.person,
                  'Driver Management',
                  Colors.orange,
                  () => onNavigate(2),
                ),
                _buildCard(
                  context,
                  Icons.account_balance_wallet,
                  'Vendors / Udhar Khata',
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VendorsRemindersScreen(),
                      ),
                    );
                  },
                ),
                _buildCard(
                  context,
                  Icons.local_gas_station,
                  'Fuel Logs & Average',
                  Colors.redAccent,
                  () => onNavigate(3),
                ),
                _buildCard(
                  context,
                  Icons.map,
                  'Routes & Location',
                  Colors.teal,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Routes & Maps screen opening...')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 26,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

