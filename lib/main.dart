import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportApp());
}

class TransportApp extends StatelessWidget {
  const TransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A237E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
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

  final List<Widget> _pages = const [
    Center(child: Text('Home Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
    Center(child: Text('Vehicles List', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
    Center(child: Text('Tours Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
    Center(child: Text('Bookings Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
    Center(child: Text('Settings & Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Manager'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.directions_bus), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Tours'),
          NavigationDestination(icon: Icon(Icons.confirmation_number), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'More'),
        ],
      ),
    );
  }
}

