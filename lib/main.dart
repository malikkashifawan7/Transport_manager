import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransportApp());
}

class TransportApp extends StatelessWidget {
  const TransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport Hisab Pro',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> fleet = [];

  @override
  void initState() {
    super.initState();
    _loadFleet();
  }

  Future<void> _loadFleet() async {
    final prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString('fleet_data');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        fleet = jsonDecode(saved);
      });
    } else {
      setState(() {
        fleet = [
          {'no': 'LES-1054', 'driver': 'Shami Khan', 'phone': '03001234567', 'loc': 'Lahore'},
          {'no': 'KHI-9921', 'driver': 'Ali Raza', 'phone': '03219876543', 'loc': 'Multan'},
        ];
      });
      _saveFleet();
    }
  }

  Future<void> _saveFleet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fleet_data', jsonEncode(fleet));
  }

  void _openWhatsApp(String phone, String vehicle) async {
    final url = Uri.parse("https://wa.me/$phone?text=Vehicle%20$vehicle%20Status%20Update?");
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

  void _addVehicleDialog() {
    final noCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: noCtrl, decoration: const InputDecoration(labelText: 'Gari No (e.g. LES-1054)')),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'WhatsApp Mobile No')),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Current Location')),
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
                    'loc': locCtrl.text,
                  });
                });
                _saveFleet();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Hisab Enterprise'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: _addVehicleDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: fleet.isEmpty
          ? const Center(child: Text('No Vehicles Added Yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: fleet.length,
              itemBuilder: (ctx, i) {
                var item = fleet[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.local_shipping, color: Colors.white),
                    ),
                    title: Text(item['no'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Driver: ${item['driver']}\nLoc: ${item['loc']}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.red),
                          onPressed: () => _openMaps(item['loc']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.green),
                          onPressed: () => _openWhatsApp(item['phone'], item['no']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

