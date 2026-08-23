import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportEnterpriseApp());
}

class TransportEnterpriseApp extends StatefulWidget {
  const TransportEnterpriseApp({super.key});

  @override
  State<TransportEnterpriseApp> createState() => _TransportEnterpriseAppState();
}

class _TransportEnterpriseAppState extends State<TransportEnterpriseApp> {
  bool isUrdu = false;

  void toggleLanguage() {
    setState(() {
      isUrdu = !isUrdu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport ERP Ultra Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: LoginScreen(
        isUrdu: isUrdu,
        onLangToggle: toggleLanguage,
      ),
    );
  }
}

// --- SECURE LOGIN / SUB-USER SYSTEM ---
class LoginScreen extends StatefulWidget {
  final bool isUrdu;
  final VoidCallback onLangToggle;

  const LoginScreen({super.key, required this.isUrdu, required this.onLangToggle});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'Admin';

  void _login() {
    if (_userCtrl.text.isNotEmpty && _passCtrl.text.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainEnterpriseShell(
            username: _userCtrl.text,
            role: _role,
            isUrdu: widget.isUrdu,
            onLangToggle: widget.onLangToggle,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isUrdu ? 'براہ کرم یوزر نیم اور پاس ورڈ درج کریں' : 'Enter valid Username and Password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool u = widget.isUrdu;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping_rounded, size: 70, color: Colors.indigo),
              const SizedBox(height: 10),
              Text(
                u ? 'ٹرانسپورٹ ای آر پی انٹرپرائز' : 'Transport ERP Enterprise',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(u ? 'لاگ ان کریں' : 'System Login', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: widget.onLangToggle,
                            icon: const Icon(Icons.language),
                            label: Text(u ? 'English' : 'اردو'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _userCtrl,
                        decoration: InputDecoration(
                          labelText: u ? 'یوزر نیم' : 'Username / Sub-User ID',
                          prefixIcon: const Icon(Icons.person),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: u ? 'پاس ورڈ' : 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _role,
                        decoration: InputDecoration(
                          labelText: u ? 'صلاحیت / رول' : 'User Role',
                          border: const OutlineInputBorder(),
                        ),
                        items: ['Admin', 'Manager', 'Sub-User / Analyst']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) => setState(() => _role = val!),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _login,
                          child: Text(
                            u ? 'سسٹم میں داخل ہوں' : 'LOGIN TO ENTERPRISE',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MAIN SHELL / NAVIGATION CONTROLLER ---
class MainEnterpriseShell extends StatefulWidget {
  final String username;
  final String role;
  final bool isUrdu;
  final VoidCallback onLangToggle;

  const MainEnterpriseShell({
    super.key,
    required this.username,
    required this.role,
    required this.isUrdu,
    required this.onLangToggle,
  });

  @override
  State<MainEnterpriseShell> createState() => _MainEnterpriseShellState();
}

class _MainEnterpriseShellState extends State<MainEnterpriseShell> {
  int _currentIndex = 0;
  List<dynamic> fleet = [];
  List<dynamic> contacts = [];
  List<dynamic> trips = [];
  List<dynamic> workshops = [];
  List<dynamic> reminders = [];

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fleet = jsonDecode(prefs.getString('pro_fleet') ?? '[]');
      contacts = jsonDecode(prefs.getString('pro_contacts') ?? '[]');
      trips = jsonDecode(prefs.getString('pro_trips') ?? '[]');
      workshops = jsonDecode(prefs.getString('pro_workshops') ?? '[]');
      reminders = jsonDecode(prefs.getString('pro_reminders') ?? '[]');

      if (fleet.isEmpty) {
        fleet = [
          {'no': 'LES-1054', 'driver': 'Shami Khan', 'phone': '03001234567', 'status': 'Active', 'location': 'Lahore Ring Road', 'type': '10-Wheeler Container'},
          {'no': 'KHI-9921', 'driver': 'Ali Raza', 'phone': '03219876543', 'status': 'In Workshop', 'location': 'Multan Goods Adda', 'type': 'Flatbed Trailer'}
        ];
      }
      if (contacts.isEmpty) {
        contacts = [
          {'name': 'Tariq Diesel Workshop', 'category': 'Workshop/Mechanic', 'phone': '03011122334', 'city': 'Lahore'},
          {'name': 'Malik Transport Client', 'category': 'Customer/Client', 'phone': '03029988776', 'city': 'Multan'}
        ];
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pro_fleet', jsonEncode(fleet));
    await prefs.setString('pro_contacts', jsonEncode(contacts));
    await prefs.setString('pro_trips', jsonEncode(trips));
    await prefs.setString('pro_workshops', jsonEncode(workshops));
    await prefs.setString('pro_reminders', jsonEncode(reminders));
  }

  void _launchWhatsApp(String phone, String msg) async {
    final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openGoogleMaps(String location) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool u = widget.isUrdu;
    final pages = [
      _buildControlDashboard(u),
      _buildFleetModule(u),
      _buildDirectoryModule(u),
      _buildWorkshopsModule(u),
      _buildBookingsAndInvoices(u),
      _buildRemindersAndHelp(u),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text(u ? 'ٹرانسپورٹ کنٹرول سینٹر' : 'Transport ERP Pro (${widget.role})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: widget.onLangToggle,
            tooltip: 'Language Toggle',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (ctx) => LoginScreen(isUrdu: u, onLangToggle: widget.onLangToggle)),
              );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard), label: u ? 'ڈیش بورڈ' : 'Dashboard'),
          NavigationDestination(icon: const Icon(Icons.local_shipping), label: u ? 'گاڑیاں' : 'Fleet'),
          NavigationDestination(icon: const Icon(Icons.contacts), label: u ? 'کانٹیکٹس' : 'Directory'),
          NavigationDestination(icon: const Icon(Icons.build), label: u ? 'ورک شاپ' : 'Workshops'),
          NavigationDestination(icon: const Icon(Icons.receipt_long), label: u ? 'ٹرپ بُکنگ' : 'Trips'),
          NavigationDestination(icon: const Icon(Icons.help_center), label: u ? 'مدد/ریمارکس' : 'Help/Notes'),
        ],
      ),
    );
  }

  // --- 1. CONTROL DASHBOARD ---
  Widget _buildControlDashboard(bool u) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.indigo.shade500]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u ? 'خوش آمدید، ${widget.username} (${widget.role})' : 'Welcome, ${widget.username} [${widget.role}]',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  u ? 'سسٹم کا مکمل لائیو کنٹرول اور تجارتی تجزیہ' : 'Live System Fleet & Operational Summary Analytics',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Divider(color: Colors.white30, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _dashMetric(u ? 'کل گاڑیاں' : 'Total Fleet', '${fleet.length}', Colors.lightBlueAccent),
                    _dashMetric(u ? 'ایکٹو ٹرپس' : 'Active Trips', '${trips.length}', Colors.lightGreenAccent),
                    _dashMetric(u ? 'ورک شاپس' : 'Workshops', '${workshops.length}', Colors.orangeAccent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(u ? 'فوری تلاش اور فلٹر (Global Search)' : 'Global Enterprise Search Engine', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: u ? 'گاڑی کا نمبر، نام یا شہر تلاش کریں...' : 'Search Vehicle No, Driver, Contact, or City...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(u ? 'گاڑیوں کی لائیو لوکیشن اور اسٹیٹس' : 'Fleet Quick Overview & Live Location', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: fleet.length,
            itemBuilder: (ctx, idx) {
              var f = fleet[idx];
              if (searchQuery.isNotEmpty &&
                  !f['no'].toString().toLowerCase().contains(searchQuery) &&
                  !f['driver'].toString().toLowerCase().contains(searchQuery)) {
                return const SizedBox.shrink();
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.local_shipping, color: Colors.white)),
                  title: Text('${f['no']} (${f['type']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Driver: ${f['driver']} | Location: ${f['location']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.map, color: Colors.redAccent),
                        tooltip: 'Google Maps Location',
                        onPressed: () => _openGoogleMaps(f['location']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.green),
                        tooltip: 'WhatsApp Contact',
                        onPressed: () => _launchWhatsApp(f['phone'], 'Assalam O Alaikum ${f['driver']}, Vehicle ${f['no']} status update?'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dashMetric(String title, String val, Color c) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  // --- 2. FLEET MODULE ---
  Widget _buildFleetModule(bool u) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        onPressed: () => _showAddVehicleDialog(u),
        icon: const Icon(Icons.add),
        label: Text(u ? 'نئی گاڑی شامل کریں' : 'Add Vehicle'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: fleet.length,
        itemBuilder: (ctx, idx) {
          var v = fleet[idx];
          return Card(
            child: ExpansionTile(
              leading: const Icon(Icons.directions_bus, color: Colors.indigo),
              title: Text(v['no'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Driver: ${v['driver']} (${v['phone']})'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle Body/Type: ${v['type']}'),
                      Text('Current Location: ${v['location']}'),
                      Text('Status: ${v['status']}'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => _launchWhatsApp(v['phone'], 'Vehicle ${v['no']} Update Required.'),
                            icon: const Icon(Icons.messenger),
                            label: const Text('WhatsApp Driver'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _openGoogleMaps(v['location']),
                            icon: const Icon(Icons.map),
                            label: const Text('Live Map'),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddVehicleDialog(bool u) {
    final noCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final typeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(u ? 'نئی گاڑی شامل کریں' : 'Add Fleet Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: noCtrl, decoration: const InputDecoration(labelText: 'Gari Number (e.g. LES-1054)')),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Driver WhatsApp/Phone')),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Current Adda / Map Location')),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type (10-Wheeler, Trailer, Flatbed)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (noCtrl.text.isNotEmpty) {
                setState(() {
                  fleet.add({
                    'no': noCtrl.text,
                    'driver': driverCtrl.text,
                    'phone': phoneCtrl.text,
                    'location': locCtrl.text,
                    'type': typeCtrl.text,
   
