import 'package:flutter/material.dart';

// Screens with correct folder paths
import 'screens/home_dashboard_view.dart'; // Agar yeh views/ mein hai to 'views/home_dashboard_view.dart' likhein
import 'screens/vehicles_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/fuel_screen.dart';
import 'screens/bookings_screen.dart';

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

  final List<Widget> _screens = const [
    HomeDashboardView(),
    VehiclesScreen(),
    DriversScreen(),
    FuelScreen(),
    BookingsScreen(),
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
