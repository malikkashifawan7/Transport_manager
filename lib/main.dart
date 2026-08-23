import 'dart00010000' if (false) 'dart:core';
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
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _openMaps(String loc) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(loc)}");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Fleet Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: noCtrl, decoration: const InputDecoration(labelText: 'Vehicle No')),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Driver Phone')),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (noCtrl.text.isNotEmpty) {
                setState(() {
                  fleet.add({'no': noCtrl.text, 'driver': driverCtrl.text, 'phone': phoneCtrl.text, 'loc': locCtrl.text});
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  contacts.add({'name': nameCtrl.text, 'phone': phoneCtrl.text, 'city': cityCtrl.text, 'cat': 'General'});
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkshopsModule() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange.shade800,
        onPressed: _addWorkshopDialog,
        child: const Icon(Icons.build, color: Colors.white),
      ),
      body: workshops.isEmpty
          ? const Center(child: Text('No Maintenance Records'))
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Workshop Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: shopCtrl, decoration: const InputDecoration(labelText: 'Shop Name')),
            TextField(controller: workCtrl, decoration: const InputDecoration(labelText: 'Details')),
            TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (shopCtrl.text.isNotEmpty) {
                setState(() {
                  workshops.add({'shop': shopCtrl.text, 'vehicle': 'Fleet', 'work': workCtrl.text, 'cost': costCtrl.text});
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsModule() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: _addTripDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: trips.isEmpty
          ? const Center(child: Text('No Trips Recorded'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trips.length,
              itemBuilder: (ctx, idx) {
                var t = trips[idx];
                return Card(
                  child: ListTile(
                    title: Text('${t['client']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Route: ${t['route']}\nFreight: Rs. ${t['freight']}'),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client Name')),
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route')),
            TextField(controller: freightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Freight (Rs.)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (clientCtrl.text.isNotEmpty) {
                setState(() {
                  trips.add({'client': clientCtrl.text, 'route': routeCtrl.text, 'freight': freightCtrl.text});
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesModule() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber.shade800,
        onPressed: _addNoteDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: notes.isEmpty
          ? const Center(child: Text('No Notes Saved'))
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
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: 'Detail')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                setState(() {
                  notes.add({'title': titleCtrl.text, 'detail': detailCtrl.text});
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
