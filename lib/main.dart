import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase initialization to prevent app freeze
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init bypassed: $e");
  }

  runApp(const AwanBrothersApp());
}

class AwanBrothersApp extends StatelessWidget {
  const AwanBrothersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awan Brothers Tours',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo.shade900),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
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
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardTab(),
    const VehiclesTab(),
    const PackagesTab(),
    const ContactTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Awan Brothers Tours & Travels',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo.shade900,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.card_travel), label: 'Packages'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Contact'),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.indigo.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Awan Brothers!',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Comfortable, safe, and premium transport services across Pakistan.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Our Key Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const ListTile(
              leading: Icon(Icons.directions_car, color: Colors.indigo),
              title: Text('Luxury Fleet Rental'),
              subtitle: Text('Coasters, HiAce, Prado & Sedan cars available.'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const ListTile(
              leading: Icon(Icons.map, color: Colors.indigo),
              title: Text('Tour Packages'),
              subtitle: Text('Northern Area tours, Hunza, Skardu, Naran & Swat.'),
            ),
          ),
        ],
      ),
    );
  }
}

class VehiclesTab extends StatelessWidget {
  const VehiclesTab({super.key});

  final List<Map<String, String>> vehicles = const [
    {'name': 'Toyota Coaster Saloon', 'type': '22 Seater AC Bus', 'price': 'Rs. 18,000 / Day'},
    {'name': 'Toyota HiAce Grand Cabin', 'type': '13 Seater Van', 'price': 'Rs. 12,000 / Day'},
    {'name': 'Toyota Prado V8', 'type': 'Luxury SUV', 'price': 'Rs. 25,000 / Day'},
    {'name': 'Honda Civic / Corolla', 'type': 'Sedan Car', 'price': 'Rs. 7,000 / Day'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final item = vehicles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              child: Icon(Icons.directions_bus, color: Colors.indigo.shade900),
            ),
            title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${item['type']}\n${item['price']}'),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Booking request for ${item['name']}')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade900,
                foregroundColor: Colors.white,
              ),
              child: const Text('Book'),
            ),
          ),
        );
      },
    );
  }
}

class PackagesTab extends StatelessWidget {
  const PackagesTab({super.key});

  final List<Map<String, String>> packages = const [
    {'title': 'Hunza Valley Tour', 'days': '5 Days / 4 Nights', 'price': 'Rs. 45,000 / Person'},
    {'title': 'Skardu Adventure Tour', 'days': '7 Days / 6 Nights', 'price': 'Rs. 65,000 / Person'},
    {'title': 'Naran Kaghan Special', 'days': '3 Days / 2 Nights', 'price': 'Rs. 28,000 / Person'},
    {'title': 'Swat Valley Tour', 'days': '4 Days / 3 Nights', 'price': 'Rs. 35,000 / Person'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final item = packages[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber.shade100,
              child: Icon(Icons.landscape, color: Colors.amber.shade900),
            ),
            title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${item['days']}\n${item['price']}'),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected package: ${item['title']}')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
              ),
              child: const Text('Details'),
            ),
          ),
        );
      },
    );
  }
}

class ContactTab extends StatelessWidget {
  const ContactTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.phone, color: Colors.green),
              title: Text('Phone / WhatsApp'),
              subtitle: Text('+92 300 0000000'),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.email, color: Colors.indigo),
              title: Text('Email Address'),
              subtitle: Text('info@awanbrothers.com'),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.location_on, color: Colors.red),
              title: Text('Head Office'),
              subtitle: Text('Awan Brothers Tours, Pakistan'),
            ),
          ),
        ],
      ),
    );
  }
}

