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
      title: 'Awan Brothers Tours',
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
  int _selectedIndex = 0;
  final List<Map<String, String>> _myBookings = [];

  void _addBooking(String customer, String service, String date) {
    setState(() {
      _myBookings.add({
        'customer': customer,
        'service': service,
        'date': date,
        'status': 'Confirmed'
      });
    });
  }

  void _showBookingDialog() {
    final nameController = TextEditingController();
    final serviceController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
            TextField(controller: serviceController, decoration: const InputDecoration(labelText: 'Vehicle / Tour Package')),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Booking Date')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && serviceController.text.isNotEmpty) {
                _addBooking(nameController.text, serviceController.text, dateController.text.isEmpty ? 'Today' : dateController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking Added Successfully!')),
                );
              }
            },
            child: const Text('Save Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(
        onNavigate: (index) => setState(() => _selectedIndex = index),
        onNewBooking: _showBookingDialog,
      ),
      const VehiclesScreen(),
      const ToursScreen(),
      BookingsScreen(bookings: _myBookings),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Awan Brothers Tours & Travels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: pages[_selectedIndex],
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

// ---------------- DASHBOARD HOME SCREEN ----------------
class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;
  final VoidCallback onNewBooking;

  const HomeScreen({super.key, required this.onNavigate, required this.onNewBooking});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: const Color(0xFF1A237E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome to Awan Tours!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Book luxury buses, coasters, and custom tour packages easily.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildActionCard(context, Icons.directions_bus, 'Fleet List', Colors.blue, () => onNavigate(1))),
              const SizedBox(width: 10),
              Expanded(child: _buildActionCard(context, Icons.map, 'Tour Packages', Colors.orange, () => onNavigate(2))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildActionCard(context, Icons.book_online, 'New Booking', Colors.green, onNewBooking)),
              const SizedBox(width: 10),
              Expanded(child: _buildActionCard(context, Icons.support_agent, 'Contact Us', Colors.purple, () => onNavigate(4))),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Fleet Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_bus, color: Color(0xFF1A237E), size: 30),
              title: const Text('Available Vehicles'),
              subtitle: const Text('Buses, Coasters & Saloon Cars'),
              trailing: const Text('12 Active', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- VEHICLES SCREEN ----------------
class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        VehicleCard(name: 'Yutong Master Bus', capacity: '50 Seats', type: 'Luxury AC', rate: 'Rs. 45,000/day'),
        VehicleCard(name: 'Toyota Coaster Saloon', capacity: '29 Seats', type: 'Executive AC', rate: 'Rs. 25,000/day'),
        VehicleCard(name: 'Toyota HiAce Grand Cabin', capacity: '14 Seats', type: 'AC Transport', rate: 'Rs. 18,000/day'),
      ],
    );
  }
}

class VehicleCard extends StatelessWidget {
  final String name, capacity, type, rate;
  const VehicleCard({super.key, required this.name, required this.capacity, required this.type, required this.rate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$capacity | $type'),
        trailing: Text(rate, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ---------------- TOURS SCREEN ----------------
class ToursScreen extends StatelessWidget {
  const ToursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        TourCard(title: 'Hunza Valley Tour', duration: '5 Days / 4 Nights', price: 'Rs. 35,000/person'),
        TourCard(title: 'Skardu Adventure', duration: '7 Days / 6 Nights', price: 'Rs. 50,000/person'),
        TourCard(title: 'Swat & Kalam Package', duration: '3 Days / 2 Nights', price: 'Rs. 22,000/person'),
      ],
    );
  }
}

class TourCard extends StatelessWidget {
  final String title, duration, price;
  const TourCard({super.key, required this.title, required this.duration, required this.price});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.terrain, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(duration),
        trailing: Text(price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ---------------- BOOKINGS SCREEN ----------------
class BookingsScreen extends StatelessWidget {
  final List<Map<String, String>> bookings;
  const BookingsScreen({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text('No Active Bookings Yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
            title: Text(b['customer'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${b['service']} - ${b['date']}'),
            trailing: Chip(label: Text(b['status'] ?? ''), backgroundColor: Colors.green.shade100),
          ),
        );
      },
    );
  }
}

// ---------------- SETTINGS SCREEN ----------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(leading: Icon(Icons.person), title: Text('Profile Settings')),
        ListTile(leading: Icon(Icons.phone), title: Text('Contact Support')),
        ListTile(leading: Icon(Icons.privacy_tip), title: Text('Privacy Policy')),
        ListTile(leading: Icon(Icons.info), title: Text('App Version'), trailing: Text('v1.0.0')),
      ],
    );
  }
}
