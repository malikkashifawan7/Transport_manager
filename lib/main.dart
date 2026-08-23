import 'dart00000000'; // placeholder
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
      title: 'Transport Hisab Pro Plus',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
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

  void _makeCall(String phone) async {
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) await launchUrl(url);
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
        title: const Text('Transport Hisab Pro Plus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 4,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_rounded), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.build_circle_rounded), label: 'Garage'),
          BottomNavigationBarItem(icon: Icon(Icons.alt_route_rounded), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt_rounded), label: 'Notes'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    double totalRevenue = trips.fold(0.0, (sum, item) => sum + (double.tryParse(item['freight'].toString()) ?? 0.0));
    double totalExpense = workshops.fold(0.0, (sum, item) => sum + (double.tryParse(item['cost'].toString()) ?? 0.0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enterprise Summary', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricItem('Fleet', '${fleet.length}', Colors.lightBlueAccent),
                    _metricItem('Active Trips', '${trips.length}', Colors.greenAccent),
                    _metricItem('Expenses', 'Rs. ${totalExpense.toInt()}', Colors.orangeAccent),
                  ],
                ),
                const Divider(color: Colors.white24, height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Revenue: Rs. ${totalRevenue.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    Text('Net Profit: Rs. ${(totalRevenue - totalExpense).toInt()}', style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Live Fleet Monitoring', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: fleet.length,
            itemBuilder: (ctx, idx) {
              var f = fleet[idx];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF1A237E), child: Icon(Icons.local_shipping, color: Colors.white, size: 20)),
                  title: Text(f['no'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Driver: ${f['driver']}\nLocation: ${f['loc']}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.phone, color: Colors.blue, size: 20), onPressed: () => _makeCall(f['phone'])),
                      IconButton(icon: const Icon(Icons.location_on, color: Colors.red, size: 20), onPressed: () => _openMaps(f['loc'])),
                      IconButton(icon: const Icon(Icons.chat, color: Colors.green, size: 20), onPressed: () => _openWhatsApp(f['phone'], 'Vehicle ${f['no']} status update?')),
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
        Text(val, style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
    Widget _buildFleetModule() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: _addVehicleDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Vehicle', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: fleet.length,
        itemBuilder: (ctx, idx) {
          var v = fleet[idx];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.directions_bus_filled, color: Color(0xFF1A237E), size: 32),
              title: Text(v['no'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Driver: ${v['driver']} (${v['phone']})\nLocation: ${v['loc']} | Type: ${v['type'] ?? 'Truck'}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  setState(() => fleet.removeAt(idx));
                  _saveAllData();
                },
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
            TextField(controller: noCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Driver Phone')),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Current Location')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (noCtrl.text.isNotEmpty) {
                setState(() {
                  fleet.add({'no': noCtrl.text, 'driver': driverCtrl.text, 'phone': phoneCtrl.text, 'loc': locCtrl.text, 'type': 'Truck'});
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: _addContactDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Contact', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: contacts.length,
        itemBuilder: (ctx, idx) {
          var c = contacts[idx];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.indigo.shade100, child: Text(c['name'].isNotEmpty ? c['name'][0] : 'C')),
              title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Role: ${c['cat']} | City: ${c['city']}\nPhone: ${c['phone']}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.phone, color: Colors.blue), onPressed: () => _makeCall(c['phone'])),
                  IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _openWhatsApp(c['phone'], 'Hello ${c['name']}')),
                ],
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange.shade800,
        onPressed: _addWorkshopDialog,
        icon: const Icon(Icons.build, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white)),
      ),
      body: workshops.isEmpty
          ? const Center(child: Text('No Maintenance/Expenses Recorded'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: workshops.length,
              itemBuilder: (ctx, idx) {
                var w = workshops[idx];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.settings, color: Colors.white)),
                    title: Text('${w['shop']} (${w['vehicle']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Work: ${w['work']}\nCost: Rs. ${w['cost']}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => workshops.removeAt(idx));
                        _saveAllData();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _addWorkshopDialog() {
    final shopCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    final workCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Workshop Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: shopCtrl, decoration: const InputDecoration(labelText: 'Workshop Name')),
            TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: workCtrl, decoration: const InputDecoration(labelText: 'Work Details')),
            TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (Rs.)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (shopCtrl.text.isNotEmpty) {
                setState(() {
                  workshops.add({'shop': shopCtrl.text, 'vehicle': vehicleCtrl.text.isEmpty ? 'Fleet' : vehicleCtrl.text, 'work': workCtrl.text, 'cost': costCtrl.text});
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: _addTripDialog,
        icon: const Icon(Icons.add_road, color: Colors.white),
        label: const Text('Add Trip', style: TextStyle(color: Colors.white)),
      ),
      body: trips.isEmpty
          ? const Center(child: Text('No Trips Recorded'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trips.length,
              itemBuilder: (ctx, idx) {
                var t = trips[idx];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.alt_route, color: Colors.white)),
                    title: Text('Client: ${t['client']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Route: ${t['route']}\nFreight Amount: Rs. ${t['freight']}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => trips.removeAt(idx));
                        _saveAllData();
                      },
                    ),
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
        title: const Text('Add Trip Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client Name')),
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route (e.g. LHR to KHI)')),
            TextField(controller: freightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Freight Amount (Rs.)')),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber.shade800,
        onPressed: _addNoteDialog,
        icon: const Icon(Icons.note_add, color: Colors.white),
        label: const Text('Add Note', style: TextStyle(color: Colors.white)),
      ),
      body: notes.isEmpty
          ? const Center(child: Text('No Notes Saved'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length,
              itemBuilder: (ctx, idx) {
                var n = notes[idx];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.note, color: Colors.amber, size: 28),
                    title: Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(n['detail']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => notes.removeAt(idx));
                        _saveAllData();
                      },
                    ),
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
        title: const Text('Add Quick Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: 'Note Details')),
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

  
