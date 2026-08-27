import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';

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

  void _showVehicleDialog({Map<String, dynamic>? vehicle}) {
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
              TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Vehicle Model')),
              TextField(controller: driverNameController, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: driverPhoneController, decoration: const InputDecoration(labelText: 'Driver Phone Number'), keyboardType: TextInputType.phone),
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
              Navigator.pop(context);
              _refreshVehicles();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Fleet & Management'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _vehicles.isEmpty
          ? const Center(child: Text('Koi Gari Add Nahi Hai. Niche (+) button dabain.'))
          : ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final v = _vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1A237E),
                      child: Icon(Icons.directions_bus, color: Colors.white),
                    ),
                    title: Text(v['vehicleNumber'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Driver: ${v['driverName'] ?? 'N/A'} (${v['driverPhone'] ?? 'N/A'})'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showVehicleDialog(vehicle: v)),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicle: v)),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showVehicleDialog(),
      ),
    );
  }
}

class VehicleDetailPage extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  List<Map<String, dynamic>> _khataList = [];
  double _totalUdhar = 0.0;
  double _totalJama = 0.0;
  double _totalBaqaya = 0.0;

  @override
  void initState() {
    super.initState();
    _loadKhataData();
  }

  void _loadKhataData() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query(
      'khata',
      where: 'vehicleNumber = ?',
      whereArgs: [widget.vehicle['vehicleNumber']],
    );

    double u = 0.0, j = 0.0;
    for (var item in data) {
      u += (item['udhar'] as num).toDouble();
      j += (item['jama'] as num).toDouble();
    }

    setState(() {
      _khataList = data;
      _totalUdhar = u;
      _totalJama = j;
      _totalBaqaya = u - j;
    });
  }

  void _addKhataEntryDialog({Map<String, dynamic>? item}) {
    final vendorController = TextEditingController(text: item?['vendorName']);
    final descController = TextEditingController(text: item?['description']);
    final udharController = TextEditingController(text: item != null ? item['udhar'].toString() : '0');
    final jamaController = TextEditingController(text: item != null ? item['jama'].toString() : '0');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Add Vendor / Shop Entry' : 'Edit Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: vendorController, decoration: const InputDecoration(labelText: 'Shop / Vendor Name')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description (Kam/Kharacha)')),
              TextField(controller: udharController, decoration: const InputDecoration(labelText: 'Udhar Amount'), keyboardType: TextInputType.number),
              TextField(controller: jamaController, decoration: const InputDecoration(labelText: 'Jama Amount'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              final u = double.tryParse(udharController.text) ?? 0.0;
              final j = double.tryParse(jamaController.text) ?? 0.0;
              final entry = {
                'vehicleNumber': widget.vehicle['vehicleNumber'],
                'vendorName': vendorController.text,
                'description': descController.text,
                'udhar': u,
                'jama': j,
                'baqaya': u - j,
                'date': DateTime.now().toString().split(' ')[0],
              };

              if (item == null) {
                await db.insert('khata', entry);
              } else {
                await db.update('khata', entry, where: 'id = ?', whereArgs: [item['id']]);
              }
              Navigator.pop(context);
              _loadKhataData();
            },
            child: const Text('Save Entry'),
          ),
        ],
      ),
    );
  }

  void _shareOnWhatsApp() async {
    String msg = "*Gari Report: ${widget.vehicle['vehicleNumber']}*\n";
    msg += "Driver: ${widget.vehicle['driverName']} (${widget.vehicle['driverPhone']})\n";
    msg += "-----------------------------------\n";
    msg += "Total Udhar: Rs. $_totalUdhar\n";
    msg += "Total Jama: Rs. $_totalJama\n";
    msg += "*Net Baqaya: Rs. $_totalBaqaya*\n\n";
    msg += "*Vendor Khata Details:*\n";

    for (var k in _khataList) {
      msg += "- ${k['vendorName']}: Udhar ${k['udhar']}, Jama ${k['jama']} (${k['description']})\n";
    }

    final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msg)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp Open Nahi Ho Saka')));
    }
  }

  void _printPDFReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Vehicle Summary: ${widget.vehicle['vehicleNumber']}", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text("Driver: ${widget.vehicle['driverName']} | Phone: ${widget.vehicle['driverPhone']}"),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text("Total Udhar: Rs. $_totalUdhar"),
                pw.Text("Total Jama: Rs. $_totalJama"),
                pw.Text("Baqaya Balance: Rs. $_totalBaqaya", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 15),
                pw.Text("Vendors & Khata Entries:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Vendor', 'Details', 'Udhar', 'Jama'],
                  data: _khataList.map((k) => [k['date'], k['vendorName'], k['description'], k['udhar'].toString(), k['jama'].toString()]).toList(),
                ),
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
        title: Text('Gari: ${widget.vehicle['vehicleNumber']}'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareOnWhatsApp, tooltip: 'WhatsApp Share'),
          IconButton(icon: const Icon(Icons.print), onPressed: _printPDFReport, tooltip: 'PDF Print'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.person, size: 36, color: Color(0xFF1A237E)),
                title: Text('Driver: ${widget.vehicle['driverName'] ?? 'Not Assigned'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Mobile: ${widget.vehicle['driverPhone'] ?? 'N/A'}'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Total Udhar', 'Rs. $_totalUdhar', Colors.red),
                    _buildStatColumn('Total Jama', 'Rs. $_totalJama', Colors.green),
                    _buildStatColumn('Net Baqaya', 'Rs. $_totalBaqaya', Colors.orange.shade900),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shops & Vendors Udhar Khata', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _addKhataEntryDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _khataList.isEmpty
                ? const Center(child: Text('Koi vendor entry nahi hai.'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _khataList.length,
                    itemBuilder: (context, index) {
                      final item = _khataList[index];
                      return Card(
                        child: ListTile(
                          title: Text(item['vendorName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item['description']}\nDate: ${item['date']}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Udhar: Rs. ${item['udhar']}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                              Text('Jama: Rs. ${item['jama']}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                              Text('Baqaya: Rs. ${item['baqaya']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          onTap: () => _addKhataEntryDialog(item: item),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
