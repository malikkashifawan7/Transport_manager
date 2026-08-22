import 'package:flutter/material.dart';

void main() {
  runApp(const TransportManagerApp());
}

class TransportManagerApp extends StatelessWidget {
  const TransportManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> categories = [
    {
      'title': 'Vehicles',
      'icon': Icons.directions_bus,
      'color': Colors.blue,
      'items': ['All Vehicles', 'Vehicle Accounts', 'Documents Expiry', 'Fuel Average']
    },
    {
      'title': 'Drivers',
      'icon': Icons.person,
      'color': Colors.orange,
      'items': ['Driver List', 'Salaries', 'Advances', 'Performance']
    },
    {
      'title': 'Bookings & Tours',
      'icon': Icons.luggage,
      'color': Colors.green,
      'items': ['Calendar Bookings', 'Company Tours', 'Local/Contract Trips', 'Route Management']
    },
    {
      'title': 'Fuel & Pumps',
      'icon': Icons.local_gas_station,
      'color': Colors.red,
      'items': ['Fuel Entries (Diesel/Petrol/LPG)', 'Pump Ledgers', 'Rate History']
    },
    {
      'title': 'Maintenance',
      'icon': Icons.build,
      'color': Colors.purple,
      'items': ['Service & Repairs', 'Oil Change History', 'Tyres Log', 'Challans & Passing']
    },
    {
      'title': 'Accounts & Ledgers',
      'icon': Icons.account_balance_wallet,
      'color': Colors.teal,
      'items': ['Cash Ledger', 'Bank Accounts', 'Party Ledgers', 'Supplier Ledgers']
    },
    {
      'title': 'Reports & Analytics',
      'icon': Icons.bar_chart,
      'color': Colors.amber,
      'items': ['Vehicle Profitability', 'Monthly Auto Reports', 'Driver Performance', 'Fuel Reports']
    },
    {
      'title': 'Backup & Settings',
      'icon': Icons.settings_applications,
      'color': Colors.grey,
      'items': ['Google Drive Backup', 'Users & Permissions', 'Recycle Bin', 'App Reminders']
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Manager Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_active), onPressed: () {}),
        ],
      ),
      body: _selectedIndex == 0 ? buildDashboard() : buildPlaceHolderTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.directions_bus), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Reports'),
        ],
      ),
    );
  }

  Widget buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Banner
          Card(
            color: Colors.indigo.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatItem(title: 'Active Fleet', value: '12'),
                  StatItem(title: 'Active Trips', value: '5'),
                  StatItem(title: 'Pending Bal', value: 'Rs. 45k'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Main Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // Main Grid Modules
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailScreen(
                          title: cat['title'],
                          subItems: List<String>.from(cat['items']),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: (cat['color'] as Color).withOpacity(0.2),
                          child: Icon(cat['icon'], color: cat['color']),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          cat['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${cat['items'].length} options',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildPlaceHolderTab() {
    return const Center(child: Text('Section view coming in Phase 2!'));
  }
}

class StatItem extends StatelessWidget {
  final String title;
  final String value;
  const StatItem({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
        Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
      ],
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String title;
  final List<String> subItems;

  const CategoryDetailScreen({super.key, required this.title, required this.subItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: subItems.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.arrow_right_alt, color: Colors.indigo),
              title: Text(subItems[index]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${subItems[index]} form will be connected to Database in Phase 2')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
