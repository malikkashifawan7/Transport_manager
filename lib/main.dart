import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportEnterpriseApp());
}

class TransportEnterpriseApp extends StatelessWidget {
  const TransportEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport Hisab ERP',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const MainEnterpriseShell(),
    );
  }
}

class MainEnterpriseShell extends StatefulWidget {
  const MainEnterpriseShell({super.key});

  @override
  State<MainEnterpriseShell> createState() => _MainEnterpriseShellState();
}

class _MainEnterpriseShellState extends State<MainEnterpriseShell> {
  int _currentIndex = 0;
  List<dynamic> fleet = [];
  List<dynamic> contacts = [];
  List<dynamic> trips = [];
  List<dynamic> workshops = [];
  List<dynamic> notes = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fleet = jsonDecode(prefs.getString('pro_fleet') ?? '[]');
      contacts = jsonDecode(prefs.getString('pro_contacts') ?? '[]');
      trips = jsonDecode(prefs.getString('pro_trips') ?? '[]');
      workshops = jsonDecode(prefs.getString('pro_workshops') ?? '[]');
      notes = jsonDecode(prefs.getString('pro_notes') ?? '[]');

      if (fleet.isEmpty) {
        fleet = [
          {'no': 'LES-1054', 'driver': 'Shami Khan', 'phone': '03001234567', 'loc': 'Lahore', 'type': '10-Wheeler'},
          {'no': 'KHI-9921', 'driver': 'Ali Raza', 'phone': '03219876543', 'loc': 'Multan', 'type': 'Trailer'},
        ];
      }
      if (contacts.isEmpty) {
        contacts = [
          {'name': 'Tariq Diesel Workshop', 'cat': 'Mechanic', 'phone': '03011122334', 'city': 'Lahore'},
          {'name': 'Malik Freight Client', 'cat': 'Client', 'phone': '03029988776', 'city': 'Multan'}
        ];
      }
    });
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pro_fleet', jsonEncode(fleet));
    await prefs.setString('pro_contacts', jsonEncode(contacts));
    await prefs.setString('pro_trips', jsonEncode(trips));
    await prefs.setString('pro_workshops', jsonEncode(workshops));
    await prefs.setString('pro_notes', jsonEncode(notes));
  }

  void _openWhatsApp(String phone, String msg) async {
    final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openMaps(String loc) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(loc)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      _buildFleetModule(),
      _buildDirectoryModule(),
      _buildWorkshopsModule(),
      _buildTripsModule(),
      _buildNotesModule(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Hisab Enterprise', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 2,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Fleet'),
          NavigationDestination(icon: Icon(Icons.contacts), label: 'Directory'),
          NavigationDestination(icon: Icon(Icons.build), label: 'Workshops'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.note_alt), label: 'Notes'),
        ],
      ),
    );
  }

  // --- 1. DASHBOARD ---
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.indigo.shade500]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fleet Management Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricItem('Total Vehicles', '${fleet.length}', Colors.lightBlueAccent),
                    _metricItem('Active Trips', '${trips.length}', Colors.lightGreenAccent),
                    _metricItem('Workshops', '${workshops.length}', Colors.orangeAccent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quick Fleet Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: fleet.length,
            itemBuilder: (ctx, idx) {
              var f = fleet[idx];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.local_shipping, color: Colors.white)),
                  title: Text(f['no'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Driver: ${f['driver']} | Loc: ${f['loc']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.map, color: Colors.red), onPressed: () => _openMaps(f['loc'])),
                      IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _openWhatsApp(f['phone'], 'Vehicle ${f['no']} Update?')),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _metricItem(String label, String val, Color c) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // --- 2. FLEET MODULE ---
  Widget _buildFleetModule() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: _addVehicleDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: fleet.length,
        itemBuilder: (ctx, idx) {
          var v = fleet[idx];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.directions_bus, color: Colors.indigo, size: 30),
              title: Text(v['no'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Driver: ${v['driver']} (${v['phone']})\nLocation: ${v['loc']} | Type: ${v['type'] ?? 'Truck'}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.map, color: Colors.red), onPressed: () => _openMaps(v['loc'])),
                  IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _openWhatsApp(v['phone'], 'Status update for ${v['no']}?')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _addVehicleDialog() {
    final noCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final typeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Fleet Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: noCtrl, decoration: const InputDecoration(labelText: 'Vehicle No')),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Driver Phone')),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location')),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Vehicle Type')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (noCtrl.text.isNotEmpty) {
                setState(() {
                  fleet.add({'no': noCtrl.text, 'driver': driverCtrl.text, 'phone': phoneCtrl.text, 'loc': locCtrl.text, 'type': typeCtrl.text});
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // --- 3. DIRECTORY ---
  Widget _buildDirectoryModule() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: _addContactDialog,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: contacts.length,
        itemBuilder: (ctx, idx) {
          var c = contacts[idx];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Role: ${c['cat']} | City: ${c['city']}\nPhone: ${c['phone']}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.chat, color: Colors.green),
                onPressed: () => _openWhatsApp(c['phone'], 'Hello ${c['name']}'),
              ),
            ),
          );
        },
      ),
    );
  }

  void _addContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final catCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Directory Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category (Client/Mechanic)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  contacts.add({'name': nameCtrl.text, 'phone': phoneCtrl.text, 'city': cityCtrl.text, 'cat': catCtrl.text});
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // --- 4. WORKSHOPS ---
  Widget _buildWorkshopsModule() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange.shade800,
        onPressed: _addWorkshopDialog,
        child: const Icon(Icons.build, color: Colors.white),
      ),
      body: workshops.isEmpty
          ? const Center(child: Text('No Workshop Records Yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: workshops.length,
              itemBuilder: (ctx, idx) {
                var w = workshops[idx];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.settings, color: Colors.white)),
                    title: Text('${w['shop']} (${w['vehicle']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Work: ${w['work']}\nCost: Rs. ${w['cost']}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  void _addWorkshopDialog() {
    final shopCtrl = TextEditingController();
    final workCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final vehCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Workshop Maintenance Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: shopCtrl, decoration: const InputDecoration(labelText: 'Workshop Name')),
              TextField(controller: vehCtrl, decoration: const InputDecoration(labelText: 'Vehicle No')),
              TextField(controller: workCtrl, decoration: const InputDecoration(labelText: 'Maintenance Details')),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (Rs.)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (shopCtrl.text.isNotEmpty) {
                setState(() {
                  workshops.add({'shop': shopCtrl.text, 'vehicle': vehCtrl.text, 'work': workCtrl.text, 'cost': costCtrl.text});
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // --- 5. TRIPS ---
  Widget _buildTripsModule() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: _addTripDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: trips.isEmpty
          ? const Center(child: Text('No Trips Recorded Yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trips.length,
              itemBuilder: (ctx, idx) {
                var t = trips[idx];
                return Card(
                  child: ListTile(
                    title: Text('${t['client']} (${t['vehicle']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Route: ${t['route']}\nFreight: Rs. ${t['freight']} | Advance: Rs. ${t['adv']}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  void _addTripDialog() {
    final clientCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final freightCtrl = TextEditingController();
    final advCtrl = TextEditingController();
    final vehCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Trip Freight Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client Name')),
              TextField(controller: vehCtrl, decoration: const InputDecoration(labelText: 'Vehicle No')),
              TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route (e.g. LHR to KHI)')),
              TextField(controller: freightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Freight Rent (Rs.)')),
              TextField(controller: advCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance (Rs.)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (clientCtrl.text.isNotEmpty) {
                setState(() {
                  trips.add({'client': clientCtrl.text, 'vehicle': vehCtrl.text, 'route': routeCtrl.text, 'freight': freightCtrl.text, 'adv': advCtrl.text});
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // --- 6. NOTES ---
  Widget _buildNotesModule() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber.shade800,
        onPressed: _addNoteDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: notes.isEmpty
          ? const Center(child: Text('No Operational Notes Saved'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length,
              itemBuilder: (ctx, idx) {
                var n = notes[idx];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.note, color: Colors.amber),
                    title: Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(n['detail']),
                  ),
                );
              },
            ),
    );
  }

  void _addNoteDialog() {
    final titleCtrl = TextEditingController();
    final detailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Reminder Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title (e.g. Token Tax)')),
              TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: 'Details / Expiry Date')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
