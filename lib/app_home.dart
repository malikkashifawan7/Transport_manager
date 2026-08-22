import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> fuelLogs = [];
  List<Map<String, dynamic>> maintenanceLogs = [];

  bool isDarkMode = false;
  String currentRole = "Admin"; // Admin / Member
  String filterDate = "";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vehicles = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v4_vehicles') ?? '[]'));
      bookings = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v4_bookings') ?? '[]'));
      fuelLogs = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v4_fuel') ?? '[]'));
      maintenanceLogs = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v4_maint') ?? '[]'));
      isDarkMode = prefs.getBool('v4_theme') ?? false;
    });
  }

  Future<void> _saveKey(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data is bool) {
      await prefs.setBool(key, data);
    } else {
      await prefs.setString(key, json.encode(data));
    }
  }

  // --- VEHICLE ADD/EDIT ---
  void _showVehicleDialog({Map<String, dynamic>? vehicleToEdit, int? index}) {
    final numCtrl = TextEditingController(text: vehicleToEdit?['number'] ?? '');
    final driverCtrl = TextEditingController(text: vehicleToEdit?['driver'] ?? '');
    final driverPhoneCtrl = TextEditingController(text: vehicleToEdit?['driverPhone'] ?? '');
    final cnicCtrl = TextEditingController(text: vehicleToEdit?['cnic'] ?? '');
    final modelCtrl = TextEditingController(text: vehicleToEdit?['model'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(vehicleToEdit == null ? 'Add Vehicle' : 'Edit Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: driverPhoneCtrl, decoration: const InputDecoration(labelText: 'Driver Phone')),
              TextField(controller: cnicCtrl, decoration: const InputDecoration(labelText: 'Driver CNIC')),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numCtrl.text.isNotEmpty) {
                final vData = {
                  'number': numCtrl.text.toUpperCase(),
                  'driver': driverCtrl.text,
                  'driverPhone': driverPhoneCtrl.text,
                  'cnic': cnicCtrl.text,
                  'model': modelCtrl.text,
                };
                setState(() {
                  if (vehicleToEdit == null) {
                    vehicles.add(vData);
                  } else {
                    vehicles[index!] = vData;
                  }
                });
                _saveKey('v4_vehicles', vehicles);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // --- TRIP ADD / EDIT DIALOG ---
  void _showTripDialog(String vNum, Map<String, dynamic> vehicle, StateSetter setLedgerState, {Map<String, dynamic>? tripToEdit, int? tripIndex}) {
    final partyCtrl = TextEditingController(text: tripToEdit?['party'] ?? '');
    final partyPhoneCtrl = TextEditingController(text: tripToEdit?['partyPhone'] ?? '');
    final addressCtrl = TextEditingController(text: tripToEdit?['address'] ?? '');
    final fromCtrl = TextEditingController(text: tripToEdit?['from'] ?? '');
    final toCtrl = TextEditingController(text: tripToEdit?['to'] ?? '');
    final kmCtrl = TextEditingController(text: tripToEdit?['km'] ?? '');
    final amountCtrl = TextEditingController(text: tripToEdit?['amount'] ?? '');
    final advanceCtrl = TextEditingController(text: tripToEdit?['advance'] ?? '');
    final expenseCtrl = TextEditingController(text: tripToEdit?['expense'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tripToEdit == null ? 'Add Detailed Trip' : 'Edit Trip'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: partyCtrl, decoration: const InputDecoration(labelText: 'Party / Client Name')),
              TextField(controller: partyPhoneCtrl, decoration: const InputDecoration(labelText: 'Party Mobile Number')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Party Address')),
              TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'From Location')),
              TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'To Location')),
              TextField(controller: kmCtrl, decoration: const InputDecoration(labelText: 'Estimated Distance (KM)')),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Total Freight Amount'), keyboardType: TextInputType.number),
              TextField(controller: advanceCtrl, decoration: const InputDecoration(labelText: 'Advance Payment'), keyboardType: TextInputType.number),
              TextField(controller: expenseCtrl, decoration: const InputDecoration(labelText: 'Trip Expense (Diesel/Tolls)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final tripData = {
                'vehicle': vNum,
                'party': partyCtrl.text,
                'partyPhone': partyPhoneCtrl.text,
                'address': addressCtrl.text,
                'from': fromCtrl.text,
                'to': toCtrl.text,
                'km': kmCtrl.text,
                'amount': amountCtrl.text,
                'advance': advanceCtrl.text,
                'expense': expenseCtrl.text,
                'date': tripToEdit?['date'] ?? DateTime.now().toString().split(' ')[0],
                'time': tripToEdit?['time'] ?? TimeOfDay.now().format(context),
              };
              setState(() {
                if (tripToEdit == null) {
                  bookings.add(tripData);
                } else {
                  bookings[tripIndex!] = tripData;
                }
              });
              _saveKey('v4_bookings', bookings);
              setLedgerState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save Trip'),
          )
        ],
      ),
    );
  }

  // --- VEHICLE LEDGER PAGE ---
  void _openVehicleMasterLedger(Map<String, dynamic> vehicle, int vIndex) {
    final String vNum = vehicle['number'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setLedgerState) {
            var vBookings = bookings.where((b) => b['vehicle'] == vNum).toList();
            if (filterDate.isNotEmpty) {
              vBookings = vBookings.where((b) => b['date'] == filterDate).toList();
            }

            double totalEarned = vBookings.fold(0, (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0') ?? 0));
            double totalAdvance = vBookings.fold(0, (sum, item) => sum + (double.tryParse(item['advance']?.toString() ?? '0') ?? 0));
            double totalExpenses = vBookings.fold(0, (sum, item) => sum + (double.tryParse(item['expense']?.toString() ?? '0') ?? 0));
            double netBalance = totalEarned - totalExpenses;

            return Scaffold(
              appBar: AppBar(
                title: Text('Vehicle: $vNum'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showVehicleDialog(vehicleToEdit: vehicle, index: vIndex);
                      setLedgerState(() {});
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setLedgerState(() {
                          filterDate = picked.toString().split(' ')[0];
                        });
                      }
                    },
                  ),
                  if (filterDate.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setLedgerState(() => filterDate = ""),
                    ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Banner
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(
                              'Driver: ${vehicle['driver']} | Phone: ${vehicle['driverPhone'] ?? 'N/A'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('CNIC: ${vehicle['cnic']} | Model: ${vehicle['model']}'),
                            const Divider(),
                            if (filterDate.isNotEmpty) Text('Filtered Date: $filterDate', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                Text('Earned: Rs. $totalEarned', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                Text('Advance: Rs. $totalAdvance', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                Text('Expenses: Rs. $totalExpenses', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                Text('Net Profit: Rs. $netBalance', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showTripDialog(vNum, vehicle, setLedgerState),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Trip'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text('🚩 Trips List (Click to view details / Edit)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...vBookings.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var b = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          title: Text('${b['party']} (${b['from']} ➔ ${b['to']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Date: ${b['date']} | Advance: Rs. ${b['advance']} | Expenses: Rs. ${b['expense']}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Rs. ${b['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                              if ((b['km'] ?? '').isNotEmpty) Text('${b['km']} KM', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          onTap: () => _showTripDetailsModal(b, vehicle, setLedgerState, idx),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- TRIP DETAILS MODAL ---
  void _showTripDetailsModal(Map<String, dynamic> trip, Map<String, dynamic> vehicle, StateSetter setLedgerState, int tripIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trip Detail: ${trip['party']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showTripDialog(trip['vehicle'], vehicle, setLedgerState, tripToEdit: trip, tripIndex: tripIndex);
                  },
                )
              ],
            ),
            const Divider(),
            Text('Party Mobile: ${trip['partyPhone'] ?? 'N/A'}'),
            Text('Party Address: ${trip['address']}'),
            Text('Route: ${trip['from']} to ${trip['to']} (${trip['km'] ?? '0'} KM)'),
            Text('Driver: ${vehicle['driver']} (${vehicle['driverPhone'] ?? 'No Mobile'})'),
            Text('Date/Time: ${trip['date']} ${trip['time']}'),
            const SizedBox(height: 8),
            Text('Total Freight: Rs. ${trip['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Advance Paid: Rs. ${trip['advance']}', style: const TextStyle(color: Colors.orange)),
            Text('Trip Expenses: Rs. ${trip['expense']}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _printSingleTripPdf(trip, vehicle),
                  icon: const Icon(Icons.print),
                  label: const Text('Export PDF'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    setState(() {
                      bookings.removeAt(tripIndex);
                    });
                    _saveKey('v4_bookings', bookings);
                    setLedgerState(() {});
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Delete', style: TextStyle(color: Colors.white)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _printSingleTripPdf(Map<String, dynamic> trip, Map<String, dynamic> vehicle) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("TRANSPORT INVOICE - ${trip['vehicle']}")),
              pw.Text("Party Name: ${trip['party']}"),
              pw.Text("Party Contact: ${trip['partyPhone'] ?? 'N/A'}"),
              pw.Text("Party Address: ${trip['address']}"),
              pw.Text("Route: ${trip['from']} -> ${trip['to']} (${trip['km'] ?? '0'} KM)"),
              pw.Text("Driver: ${vehicle['driver']} (Phone: ${vehicle['driverPhone'] ?? 'N/A'})"),
              pw.Text("Date & Time: ${trip['date']} ${trip['time']}"),
              pw.Divider(),
              pw.Text("Total Freight: Rs. ${trip['amount']}"),
              pw.Text("Advance Payment: Rs. ${trip['advance']}"),
              pw.Text("Trip Expense: Rs. ${trip['expense']}"),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- SETTINGS AND USER MANUAL ---
  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settings & Help Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('User Guide / Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 5),
              Text('English:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('1. Tap "+" to add vehicles & drivers.\n2. Tap any vehicle card to add trips date-wise.\n3. Click trip card to view/edit details or print invoice.\n4. Use calendar icon on top to filter date-wise entries.'),
              SizedBox(height: 10),
              Text('Urdu (رہنمائی):', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('1. نئی گاڑی شامل کرنے کے لیے نیچے + پر کلک کریں۔\n2. گاڑی کے تمام ٹرپ داخل کرنے کے لیے گاڑی کا کارڈ اوپن کریں۔\n3. کسی بھی ٹرپ کو ایڈٹ یا پرنٹ کرنے کے لیے اس پر کلک کریں۔\n4. اوپر والے کلینڈر سے تاریخ کے حساب سے رپورٹ دیکھیں۔'),
              Divider(),
              Text('Version: 4.0.0 (Enterprise Fleet Sync)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
       
