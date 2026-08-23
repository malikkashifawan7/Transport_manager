import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportUltimateApp());
}

class TransportUltimateApp extends StatelessWidget {
  const TransportUltimateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport ERP Ultimate',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const EnterpriseMainDashboard(),
    );
  }
}

class EnterpriseMainDashboard extends StatefulWidget {
  const EnterpriseMainDashboard({super.key});

  @override
  State<EnterpriseMainDashboard> createState() => _EnterpriseMainDashboardState();
}

class _EnterpriseMainDashboardState extends State<EnterpriseMainDashboard> {
  int _tabIndex = 0;
  List<dynamic> vehicles = [];
  List<dynamic> contacts = [];
  List<dynamic> notes = [];
  List<dynamic> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vehicles = jsonDecode(prefs.getString('vehicles_v8') ?? '[]');
      contacts = jsonDecode(prefs.getString('contacts_v8') ?? '[]');
      notes = jsonDecode(prefs.getString('notes_v8') ?? '[]');
      bookings = jsonDecode(prefs.getString('bookings_v8') ?? '[]');

      if (vehicles.isEmpty) {
        vehicles = [
          {
            'id': 'v1',
            'no': 'LES-1054',
            'driver': 'Shami Khan',
            'phone': '0300-1234567',
            'type': '10-Wheeler',
            'address': 'Lahore Adda',
            'workshop': 'Al-Madina Workshop'
          }
        ];
      }
      if (contacts.isEmpty) {
        contacts = [
          {'name': 'Tariq Diesel Shop', 'category': 'Vendor/Workshop', 'phone': '0301-1122334', 'address': 'Ring Road Lahore'},
          {'name': 'Malik Motors Client', 'category': 'Customer', 'phone': '0302-9988776', 'address': 'Multan Goods Adda'}
        ];
      }
      isLoading = false;
    });
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vehicles_v8', jsonEncode(vehicles));
    await prefs.setString('contacts_v8', jsonEncode(contacts));
    await prefs.setString('notes_v8', jsonEncode(notes));
    await prefs.setString('bookings_v8', jsonEncode(bookings));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      _buildDashboardTab(),
      _buildContactsTab(),
      _buildVehiclesTab(),
      _buildNotePadTab(),
      _buildBookingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport ERP Enterprise v8.0', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade100,
      ),
      body: screens[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.contacts), label: 'Directory'),
          NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Fleet'),
          NavigationDestination(icon: Icon(Icons.note_alt), label: 'NotePad'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Bookings'),
        ],
      ),
    );
  }

  // --- DASHBOARD ---
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Card(
            color: Colors.indigo.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('TRANSPORT ENTERPRISE CONTROL CENTER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dashStat('Garriyan', '${vehicles.length}', Colors.cyanAccent),
                      _dashStat('Contacts Directory', '${contacts.length}', Colors.amberAccent),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dashStat('Daily Memos', '${notes.length}', Colors.greenAccent),
                      _dashStat('Active Trips', '${bookings.length}', Colors.orangeAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashStat(String title, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(val, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- CONTACTS DIRECTORY ---
  Widget _buildContactsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactDialog(),
        child: const Icon(Icons.person_add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: contacts.length,
        itemBuilder: (ctx, idx) {
          var c = contacts[idx];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: c['category'] == 'Customer' ? Colors.green.shade100 : Colors.orange.shade100,
                child: Icon(c['category'] == 'Customer' ? Icons.person : Icons.store, color: Colors.indigo),
              ),
              title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Cat: ${c['category']} | Mobile: ${c['phone']}\nAddress: ${c['address']}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.indigo),
                onPressed: () => _showContactDialog(contact: c, index: idx),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showContactDialog({Map<String, dynamic>? contact, int? index}) {
    final nameCtrl = TextEditingController(text: contact?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: contact?['phone'] ?? '');
    final addressCtrl = TextEditingController(text: contact?['address'] ?? '');
    String category = contact?['category'] ?? 'Customer';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          title: Text(contact == null ? 'Add New Contact' : 'Edit Contact Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name / Shop / Workshop Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Number')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address / Adda Location')),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                items: ['Customer', 'Vendor/Workshop', 'Driver', 'Mechanic'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (v) => setDlg(() => category = v!),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    Map<String, dynamic> item = {
                      'name': nameCtrl.text,
                      'phone': phoneCtrl.text,
                      'address': addressCtrl.text,
                      'category': category,
                    };
                    if (index == null) {
                      contacts.add(item);
                    } else {
                      contacts[index] = item;
                    }
                  });
                  _saveAllData();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Profile'),
            )
          ],
        ),
      ),
    );
  }

  // --- FLEET & VEHICLES MANAGER ---
  Widget _buildVehiclesTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVehicleDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: vehicles.length,
        itemBuilder: (ctx, idx) {
          var v = vehicles[idx];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
              title: Text(v['no'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Driver: ${v['driver']} (${v['phone']})\nWorkshop: ${v['workshop']} | Adda: ${v['address']}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.indigo),
                onPressed: () => _showVehicleDialog(vehicle: v, index: idx),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVehicleDialog({Map<String, dynamic>? vehicle, int? index}) {
    final noCtrl = TextEditingController(text: vehicle?['no'] ?? '');
    final driverCtrl = TextEditingController(text: vehicle?['driver'] ?? '');
    final phoneCtrl = TextEditingController(text: vehicle?['phone'] ?? '');
    final typeCtrl = TextEditingController(text: vehicle?['type'] ?? '');
    final addressCtrl = TextEditingController(text: vehicle?['address'] ?? '');
    final workshopCtrl = TextEditingController(text: vehicle?['workshop'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(vehicle == null ? 'Add New Vehicle' : 'Edit Vehicle Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: noCtrl, decoration: const InputDecoration(labelText: 'Gari Number')),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Driver Phone')),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Body Type / Wheeler')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Base Location / Adda')),
              TextField(controller: workshopCtrl, decoration: const InputDecoration(labelText: 'Assigned Workshop')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (noCtrl.text.isNotEmpty) {
                setState(() {
                  Map<String, dynamic> item = {
                    'no': noCtrl.text,
                    'driver': driverCtrl.text,
                    'phone': phoneCtrl.text,
                    'type': typeCtrl.text,
                    'address': addressCtrl.text,
                    'workshop': workshopCtrl.text,
                  };
                  if (index == null) {
                    vehicles.add(item);
                  } else {
                    vehicles[index] = item;
                  }
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Vehicle'),
          )
        ],
      ),
    );
  }

  // --- NOTE PAD MODULE ---
  Widget _buildNotePadTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showNoteDialog,
        child: const Icon(Icons.note_add),
      ),
      body: notes.isEmpty
          ? const Center(child: Text('Koi Note / Memo add nahi hai.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length,
              itemBuilder: (ctx, idx) {
                var n = notes[idx];
                return Card(
                  color: Colors.amber.shade50,
                  child: ListTile(
                    title: Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${n['details']}\nDate: ${n['date']}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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

  void _showNoteDialog() {
    final titleCtrl = TextEditingController();
    final detailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Daily Note / Memo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: detailCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Details / Note')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                setState(() {
                  notes.add({
                    'title': titleCtrl.text,
                    'details': detailCtrl.text,
                    'date': DateTime.now().toString().split(' ')[0]
                  });
                });
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Memo'),
          )
        ],
      ),
    );
  }

  // --- BOOKINGS MODULE ---
  Widget _buildBookingsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showBookingDialog,
        child: const Icon(Icons.add),
      ),
      body: bookings.isEmpty
          ? const Center(child: Text('Koi trip booking nahi hai.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bookings.length,
              itemBuilder: (ctx, idx) {
                var b = bookings[idx];
                return Card(
                  child: ListTile(
                    title: Text('${b['client']} (${b['vehicle']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Route: ${b['route']}\nFreight: Rs. ${b['freight']} | Advance: Rs. ${b['advance']}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.print, color: Colors.indigo),
                      onPressed: () => _printInvoicePDF(b),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showBookingDialog() {
    final clientCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final freightCtrl = TextEditingController();
    final advanceCtrl = TextEditingController();
    String selectedVehicle = vehicles.isNotEmpty ? vehicles[0]['no'] : 'General';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          title: const Text('Generate Dynamic Trip Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client Name')),
              TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route (e.g. LHR to KHI)')),
              TextField(controller: freightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Freight Rent (Rs.)')),
              TextField(controller: advanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance Received (Rs.)')),
              DropdownButton<String>(
                value: selectedVehicle,
                isExpanded: true,
                items: vehicles.map((v) => DropdownMenuItem<String>(value: v['no'].toString(), child: Text(v['no'].toString()))).toList(),
                onChanged: (v) => setDlg(() => selectedVehicle = v!),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  bookings.add({
                    'client': clientCtrl.text,
                    'route': routeCtrl.text,
                    'freight': double.tryParse(freightCtrl.text) ?? 0.0,
                    'advance': double.tryParse(advanceCtrl.text) ?? 0.0,
                    'vehicle': selectedVehicle,
                    'date': DateTime.now().toString().split(' ')[0]
                  });
                });
                _saveAllData();
                Navigator.pop(ctx);
              },
              child: const Text('Save Booking'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _printInvoicePDF(Map<String, dynamic> b) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TRANSPORT ENTERPRISE FREIGHT RECEIPT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Client Name: ${b['client']}'),
              pw.Text('Assigned Vehicle: ${b['vehicle']}'),
              pw.Text('Route: ${b['route']}'),
              pw.Text('Date: ${b['date']}'),
              pw.SizedBox(height: 15),
              pw.Text('Total Freight Amount: Rs. ${b['freight']}'),
              pw.Text('Advance Paid: Rs. ${b['advance']}'),
              pw.Text('Net Payable Balance: Rs. ${(b['freight'] - b['advance'])}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Spacer(),
              pw.Divider(),
              pw.Center(child: pw.Text('Powered by Transport ERP Ultimate'))
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}

