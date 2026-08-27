import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';
import 'vehicle_detail_screen.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _refreshVehicles();
  }

  void _refreshVehicles() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('vehicles');
    setState(() {
      _vehicles = data;
    });
  }

  void _showVehicleDialog([Map<String, dynamic>? vehicle]) {
    final numController = TextEditingController(text: vehicle?['vehicleNumber']);
    final modelController = TextEditingController(text: vehicle?['model']);
    final driverNameController = TextEditingController(text: vehicle?['driverName']);
    final driverPhoneController = TextEditingController(text: vehicle?['driverPhone']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(vehicle == null ? 'Add New Vehicle' : 'Edit Vehicle Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numController, decoration: const InputDecoration(labelText: 'Gari Number (e.g. LES-1234)')),
              TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Vehicle Model / Type')),
              TextField(controller: driverNameController, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: driverPhoneController, decoration: const InputDecoration(labelText: 'Driver Mobile Number')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              final data = {
                'vehicleNumber': numController.text,
                'model': modelController.text,
                'driverName': driverNameController.text,
                'driverPhone': driverPhoneController.text,
              };

              if (vehicle == null) {
                await db.insert('vehicles', data);
              } else {
                await db.update('vehicles', data, where: 'id = ?', whereArgs: [vehicle['id']]);
              }
              if (mounted) Navigator.pop(context);
              _refreshVehicles();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _printVehiclePdf(Map<String, dynamic> vehicle) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Awan Brothers Tours & Travels', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Vehicle Master Details Slip', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text('Vehicle Number: ${vehicle['vehicleNumber']}'),
                pw.Text('Model / Specification: ${vehicle['model']}'),
                pw.Text('Assigned Driver: ${vehicle['driverName']}'),
                pw.Text('Driver Mobile: ${vehicle['driverPhone']}'),
                pw.SizedBox(height: 20),
                pw.Text('Status: Active Fleet'),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Fleet Management'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: () => _showVehicleDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _vehicles.isEmpty
          ? const Center(child: Text('No vehicles added yet. Click + to add.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VehicleDetailScreen(vehicle: {
                            'name': vehicle['vehicleNumber'],
                            'number': vehicle['vehicleNumber'],
                            'type': vehicle['model'],
                            'driver': vehicle['driverName'],
                            'status': 'Available',
                          }),
                        ),
                      );
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1A237E),
                      child: Icon(Icons.directions_bus, color: Colors.white),
                    ),
                    title: Text(
                      vehicle['vehicleNumber'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text('Model: ${vehicle['model']}\nDriver: ${vehicle['driverName']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.blue),
                          onPressed: () => _printVehiclePdf(vehicle),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () async {
                            final Uri phoneUri = Uri.parse('tel:${vehicle['driverPhone']}');
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showVehicleDialog(vehicle),
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
