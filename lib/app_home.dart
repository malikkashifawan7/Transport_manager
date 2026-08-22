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
  bool isDarkMode = false;
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
              TextField(controller: expenseCtrl, decoration: const InputDecoration(labelText: 'Trip Expense'), keyboardType: TextInputType.number),
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
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text('Driver: ${vehicle['driver']} | Phone: ${vehicle['driverPhone'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                Text('Net: Rs. $netBalance', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _showTripDialog(vNum, vehicle, setLedgerState),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Trip'),
                      ),
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
                          subtitle: Text('Date: ${b['date']} | Advance: Rs. ${b['advance']} | Expense: Rs. ${b['expense']}'),
                          trailing: Text('Rs. ${b['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
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
  
