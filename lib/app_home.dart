import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> maintenanceLogs = [];
  bool isDarkMode = false;
  String filterDate = "";

  final String companyName = "Rashid Tours & Travels";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vehicles = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v5_vehicles') ?? '[]'));
      bookings = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v5_bookings') ?? '[]'));
      maintenanceLogs = List<Map<String, dynamic>>.from(json.decode(prefs.getString('v5_maint') ?? '[]'));
      isDarkMode = prefs.getBool('v5_theme') ?? false;
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

  void _showVehicleDialog({Map<String, dynamic>? vehicleToEdit, int? index}) {
    final numCtrl = TextEditingController(text: vehicleToEdit?['number'] ?? '');
    final driverCtrl = TextEditingController(text: vehicleToEdit?['driver'] ?? '');
    final driverPhoneCtrl = TextEditingController(text: vehicleToEdit?['driverPhone'] ?? '');
    final cnicCtrl = TextEditingController(text: vehicleToEdit?['cnic'] ?? '');
    final modelCtrl = TextEditingController(text: vehicleToEdit?['model'] ?? '');
    final currentKmCtrl = TextEditingController(text: vehicleToEdit?['currentKm'] ?? '0');
    final nextOilKmCtrl = TextEditingController(text: vehicleToEdit?['nextOilKm'] ?? '5000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(vehicleToEdit == null ? 'Add New Vehicle' : 'Edit Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number (e.g. LEC-1234)')),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: driverPhoneCtrl, decoration: const InputDecoration(labelText: 'Driver Mobile Number')),
              TextField(controller: cnicCtrl, decoration: const InputDecoration(labelText: 'Driver CNIC')),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Vehicle Model/Make')),
              TextField(controller: currentKmCtrl, decoration: const InputDecoration(labelText: 'Current Odometer (KM)'), keyboardType: TextInputType.number),
              TextField(controller: nextOilKmCtrl, decoration: const InputDecoration(labelText: 'Oil Change Due at (KM)'), keyboardType: TextInputType.number),
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
                  'currentKm': currentKmCtrl.text,
                  'nextOilKm': nextOilKmCtrl.text,
                };
                setState(() {
                  if (vehicleToEdit == null) {
                    vehicles.add(vData);
                  } else {
                    vehicles[index!] = vData;
                  }
                });
                _saveKey('v5_vehicles', vehicles);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Vehicle'),
          ),
        ],
      ),
    );
  }

  void _showTripDialog(String vNum, Map<String, dynamic> vehicle, StateSetter setLedgerState, {Map<String, dynamic>? tripToEdit, int? tripIndex}) {
    String clientType = tripToEdit?['clientType'] ?? 'Company';
    final partyCtrl = TextEditingController(text: tripToEdit?['party'] ?? '');
    final partyPhoneCtrl = TextEditingController(text: tripToEdit?['partyPhone'] ?? '');
    final addressCtrl = TextEditingController(text: tripToEdit?['address'] ?? '');
    final fromCtrl = TextEditingController(text: tripToEdit?['from'] ?? '');
    final toCtrl = TextEditingController(text: tripToEdit?['to'] ?? '');
    final kmCtrl = TextEditingController(text: tripToEdit?['km'] ?? '');
    final amountCtrl = TextEditingController(text: tripToEdit?['amount'] ?? '');
    final advanceCtrl = TextEditingController(text: tripToEdit?['advance'] ?? '');
    final dieselLitersCtrl = TextEditingController(text: tripToEdit?['dieselLiters'] ?? '');
    final dieselCostCtrl = TextEditingController(text: tripToEdit?['dieselCost'] ?? '');
    final otherExpenseCtrl = TextEditingController(text: tripToEdit?['otherExpense'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tripToEdit == null ? 'Add New Trip' : 'Edit Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: clientType,
                  decoration: const InputDecoration(labelText: 'Client Category'),
                  items: ['Company', 'School', 'College', 'Factory', 'Personal Tour', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => clientType = val!),
                ),
                TextField(controller: partyCtrl, decoration: const InputDecoration(labelText: 'Client / Contract Name')),
                TextField(controller: partyPhoneCtrl, decoration: const InputDecoration(labelText: 'Contact Mobile Number'), keyboardType: TextInputType.phone),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address / Location Details')),
                TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'From Route')),
                TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'To Route')),
                TextField(controller: kmCtrl, decoration: const InputDecoration(labelText: 'Total Distance Covered (KM)'), keyboardType: TextInputType.number),
                TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Total Fare / Freight Amount'), keyboardType: TextInputType.number),
                TextField(controller: advanceCtrl, decoration: const InputDecoration(labelText: 'Advance Received'), keyboardType: TextInputType.number),
                TextField(controller: dieselLitersCtrl, decoration: const InputDecoration(labelText: 'Diesel Filled (Liters)'), keyboardType: TextInputType.number),
                TextField(controller: dieselCostCtrl, decoration: const InputDecoration(labelText: 'Diesel Total Cost'), keyboardType: TextInputType.number),
                TextField(controller: otherExpenseCtrl, decoration: const InputDecoration(labelText: 'Toll/Other Work Expenses'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                double totalExp = (double.tryParse(dieselCostCtrl.text) ?? 0) + (double.tryParse(otherExpenseCtrl.text) ?? 0);
                double km = double.tryParse(kmCtrl.text) ?? 0;
                double liters = double.tryParse(dieselLitersCtrl.text) ?? 0;
                double avg = (liters > 0) ? (km / liters) : 0;

                final tripData = {
                  'vehicle': vNum,
                  'clientType': clientType,
                  'party': partyCtrl.text,
                  'partyPhone': partyPhoneCtrl.text,
                  'address': addressCtrl.text,
                  'from': fromCtrl.text,
                  'to': toCtrl.text,
                  'km': kmCtrl.text,
                  'amount': amountCtrl.text,
                  'advance': advanceCtrl.text,
                  'dieselLiters': dieselLitersCtrl.text,
                  'dieselCost': dieselCostCtrl.text,
                  'otherExpense': otherExpenseCtrl.text,
                  'expense': totalExp.toString(),
                  'fuelAvg': avg.toStringAsFixed(2),
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
                _saveKey('v5_bookings', bookings);
                setLedgerState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Save Trip'),
            )
          ],
        ),
      ),
    );
  }

  void _showMaintenanceDialog(String vNum, StateSetter setLedgerState) {
    final typeCtrl = TextEditingController(text: 'Oil Change & Maintenance');
    final costCtrl = TextEditingController();
    final kmAtServiceCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Maintenance / Oil Work'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Service Type (Oil, Tuning, Repairs)')),
              TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Total Cost (Rs.)'), keyboardType: TextInputType.number),
              TextField(controller: kmAtServiceCtrl, decoration: const InputDecoration(labelText: 'Current KM Reading'), keyboardType: TextInputType.number),
              TextField(controller: detailsCtrl, decoration: const InputDecoration(labelText: 'Work / Parts Description')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final mainData = {
                'vehicle': vNum,
                'type': typeCtrl.text,
                'cost': costCtrl.text,
                'km': kmAtServiceCtrl.text,
                'details': detailsCtrl.text,
                'date': DateTime.now().toString().split(' ')[0],
              };
              setState(() {
                maintenanceLogs.add(mainData);
              });
              _saveKey('v5_maint', maintenanceLogs);
              setLedgerState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save Maintenance Log'),
          )
        ],
      ),
    );
  }
  void _openVehicleMasterLedger(Map<String, dynamic> vehicle, int vIndex) {
    final String vNum = vehicle['number'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setLedgerState) {
            var vBookings = bookings.where((b) => b['vehicle'] == vNum).toList();
            var vMaints = maintenanceLogs.where((m) => m['vehicle'] == vNum).toList();

            if (filterDate.isNotEmpty) {
              vBookings = vBookings.where((b) => b['date'] == filterDate).toList();
              vMaints = vMaints.where((m) => m['date'] == filterDate).toList();
            }

            double totalEarned = vBookings.fold(0, (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0') ?? 0));
            double totalAdvance = vBookings.fold(0, (sum, item) => sum + (double.tryParse(item['advance']?.toString() ?? '0') ?? 0));
            double totalTripExpenses = vBookings.fold(0, (sum, item) => sum + (double.tryParse(item['expense']?.toString() ?? '0') ?? 0));
            double totalMaintExpenses = vMaints.fold(0, (sum, item) => sum + (double.tryParse(item['cost']?.toString() ?? '0') ?? 0));
            double grandExpenses = totalTripExpenses + totalMaintExpenses;
            double netBalance = totalEarned - grandExpenses;

            double currKm = double.tryParse(vehicle['currentKm']?.toString() ?? '0') ?? 0;
            double nextOilKm = double.tryParse(vehicle['nextOilKm']?.toString() ?? '0') ?? 0;
            bool oilWarning = currKm >= nextOilKm && nextOilKm > 0;

            return Scaffold(
              appBar: AppBar(
                title: Text('$vNum - Ledger'),
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
                    if (oilWarning)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        color: Colors.red.shade100,
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '⚠️ OIL CHANGE REMINDER! Vehicle passed $nextOilKm KM limit.',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(companyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                            const Divider(),
                            Text('Driver: ${vehicle['driver']} | Phone: ${vehicle['driverPhone'] ?? 'N/A'}'),
                            Text('CNIC: ${vehicle['cnic']} | Model: ${vehicle['model']}'),
                            Text('Current Meter: $currKm KM | Next Oil Due: $nextOilKm KM', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Divider(),
                            if (filterDate.isNotEmpty) Text('Filtered Date: $filterDate', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 10,
                              runSpacing: 5,
                              children: [
                                Text('Fare: Rs. $totalEarned', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                Text('Advance: Rs. $totalAdvance', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                Text('Expenses: Rs. $grandExpenses', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: () => _showMaintenanceDialog(vNum, setLedgerState),
                          icon: const Icon(Icons.build, color: Colors.white),
                          label: const Text('Log Maintenance/Oil', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text('🚩 Registered Trips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    ...vBookings.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var b = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          title: Text('${b['clientType']}: ${b['party']} (${b['from']} ➔ ${b['to']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Date: ${b['date']} | Fuel Avg: ${b['fuelAvg']} KM/L | Exp: Rs. ${b['expense']}'),
                          trailing: Text('Rs. ${b['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                          onTap: () => _showTripDetailsModal(b, vehicle, setLedgerState, idx),
                        ),
                      );
                    }),
                    const SizedBox(height: 15),
                    const Text('🔧 Maintenance & Oil Change Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    ...vMaints.map((m) => Card(
                          color: Colors.grey.shade100,
                          child: ListTile(
                            leading: const Icon(Icons.oil_barrel, color: Colors.orange),
                            title: Text('${m['type']} - Rs. ${m['cost']}'),
                            subtitle: Text('Date: ${m['date']} | Reading: ${m['km']} KM\nNote: ${m['details']}'),
                          ),
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

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
                Text('${trip['clientType']}: ${trip['party']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Text('Contact Phone: ${trip['partyPhone'] ?? 'N/A'}'),
            Text('Address Details: ${trip['address']}'),
            Text('Route: ${trip['from']} to ${trip['to']} (${trip['km'] ?? '0'} KM)'),
            Text('Driver: ${vehicle['driver']} (${vehicle['driverPhone'] ?? 'N/A'})'),
            Text('Date/Time: ${trip['date']} ${trip['time']}'),
            Text('Fuel Consumed: ${trip['dieselLiters']} L | Cost: Rs. ${trip['dieselCost']}'),
            Text('Calculated Mileage Avg: ${trip['fuelAvg']} KM/Liter', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            const SizedBox(height: 8),
            Text('Total Freight: Rs. ${trip['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Advance Received: Rs. ${trip['advance']}', style: const TextStyle(color: Colors.orange)),
            Text('Trip Expenses: Rs. ${trip['expense']}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openMapRoute(trip['from'], trip['to']),
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text('Google Map', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: () => _shareWhatsAppInvoice(trip, vehicle),
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
                ElevatedButton.icon(
                  onPressed: () => _printSingleTripPdf(trip, vehicle),
                  icon: const Icon(Icons.print),
                  label: const Text('PDF Invoice'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _openMapRoute(String origin, String destination) async {
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch Google Maps')));
      }
    }
  }

  void _shareWhatsAppInvoice(Map<String, dynamic> trip, Map<String, dynamic> vehicle) async {
    String phone = trip['partyPhone'] ?? '';
    String msg = "*$companyName*\n"
        "*Trip Invoice / Details*\n\n"
        "Vehicle: ${trip['vehicle']}\n"
        "Client Type: ${trip['clientType']}\n"
        "Client Name: ${trip['party']}\n"
        "Route: ${trip['from']} -> ${trip['to']} (${trip['km']} KM)\n"
        "Driver: ${vehicle['driver']} (${vehicle['driverPhone']})\n"
        "Date: ${trip['date']}\n\n"
        "*Total Freight:* Rs. ${trip['amount']}\n"
        "*Advance Received:* Rs. ${trip['advance']}\n"
        "*Remaining Balance:* Rs. ${(double.tryParse(trip['amount'] ?? '0') ?? 0) - (double.tryParse(trip['advance'] ?? '0') ?? 0)}\n\n"
        "Thank you for choosing Rashid Tours & Travels!";

    final Uri url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(msg)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp not installed or invalid number')));
      }
    }
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
              pw.Text(companyName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text("Official Transport Invoice", style: const pw.TextStyle(fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text("Vehicle Reg No: ${trip['vehicle']}"),
              pw.Text("Client Category: ${trip['clientType']}"),
              pw.Text("Client Name: ${trip['party']}"),
              pw.Text("Contact Mobile: ${trip['partyPhone'] ?? 'N/A'}"),
              pw.Text("Address: ${trip['address']}"),
              pw.Text("Route: ${trip['from']} -> ${trip['to']} (${trip['km'] ?? '0'} KM)"),
              pw.Text("Driver Details: ${vehicle['driver']} (${vehicle['driverPhone'] ?? 'N/A'})"),
              pw.Text("Date & Time: ${trip['date']} ${trip['time']}"),
              pw.Divider(),
              pw.Text("Total Freight Amount: Rs. ${trip['amount']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Advance Paid: Rs. ${trip['advance']}"),
              pw.Text("Balance Due: Rs. ${(double.tryParse(trip['amount'] ?? '0') ?? 0) - (double.tryParse(trip['advance'] ?? '0') ?? 0)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Thank you for your business!", style: const pw.TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rashid Tours System Info'),
        content: const Text('Version 5.0 - Fleet & Maintenance Management System.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(companyName),
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() => isDarkMode = !isDarkMode);
                _saveKey('v5_theme', isDarkMode);
              },
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _openSettingsDialog,
            )
          ],
        ),
        body: vehicles.isEmpty
            ? const Center(child: Text('No vehicles added yet. Tap + to add.'))
            : ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (ctx, i) => Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.directions_bus, size: 36, color: Colors.blue),
                    title: Text(vehicles[i]['number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('Driver: ${vehicles[i]['driver']} | Phone: ${vehicles[i]['driverPhone'] ?? 'N/A'}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _openVehicleMasterLedger(vehicles[i], i),
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showVehicleDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

