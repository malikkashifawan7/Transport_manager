import 'package:flutter/material.dart';

void main() {
  runApp(const TransportHisabApp());
}

class TransportHisabApp extends StatelessWidget {
  const TransportHisabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport Hisab',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TransportHomePage(),
    );
  }
}

class TransportHomePage extends StatefulWidget {
  const TransportHomePage({super.key});

  @override
  State<TransportHomePage> createState() => _TransportHomePageState();
}

class _TransportHomePageState extends State<TransportHomePage> {
  bool isLoggedIn = false;
  final String appPin = "1234";
  final TextEditingController pinCtrl = TextEditingController();

  List<Map<String, dynamic>> vehicles = [
    {
      'id': '1',
      'number': 'Gari 1054',
      'driver': 'Shami',
      'phone': '0302-1234567',
      'cnic': '36302-XXXXXXX-1',
      'type': 'Company/Factory',
      'fixedSalary': 25000.0,
      'trips': [
        {'id': 't1', 'title': 'ww (mln)', 'income': 20000.0, 'expense': 8000.0, 'date': '2026-08-22', 'category': 'Factory'}
      ],
      'driverPayments': [
        {'id': 'p1', 'amount': 5000.0, 'note': 'beti k leay', 'date': '2026-08-22'}
      ],
      'oilChangeKm': 45000,
      'nextOilChangeKm': 50000,
      'fuelAverage': 12.5,
    }
  ];

  List<Map<String, dynamic>> recycleBin = [];

  List<Map<String, dynamic>> fuelRates = [
    {'location': 'Lahore', 'petrol': 275.50, 'diesel': 282.00, 'updated': '2026-08-20', 'changed': true},
    {'location': 'Multan', 'petrol': 276.00, 'diesel': 283.50, 'updated': '2026-08-21', 'changed': false},
    {'location': 'Karachi', 'petrol': 274.00, 'diesel': 280.00, 'updated': '2026-08-15', 'changed': false},
  ];

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_bus, size: 70, color: Colors.blue),
                const SizedBox(height: 10),
                const Text('Rashid Tours Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Enter PIN (1234)'),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                  onPressed: () {
                    if (pinCtrl.text == appPin) {
                      setState(() => isLoggedIn = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong Password! Use 1234')));
                    }
                  },
                  child: const Text('Login'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Hisab Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'All Drivers Details',
            onPressed: _showAllDriversDialog,
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: 'All Vehicles Total Ledger',
            onPressed: _showTotalCombinedLedger,
          ),
          IconButton(
            icon: const Icon(Icons.local_gas_station),
            tooltip: 'Fuel Rates',
            onPressed: _showFuelRatesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Recycle Bin',
            onPressed: _openRecycleBin,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => setState(() => isLoggedIn = false),
          ),
        ],
      ),
      body: vehicles.isEmpty
          ? const Center(child: Text('Koi gari add nahi hai. Niche + ka button dabayein.'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.directions_bus, size: 36, color: Colors.blue),
                  title: Text('${vehicles[i]['number']} (${vehicles[i]['type']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Driver: ${vehicles[i]['driver']} | Tel: ${vehicles[i]['phone']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _editVehicleDialog(i),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () => _openGariSinglePageLedger(vehicles[i]),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVehicleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- NEW FEATURES DIALOGS ---

  void _showAllDriversDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('All Drivers Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: vehicles.length,
            itemBuilder: (c, i) {
              var v = vehicles[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(v['driver'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Vehicle: ${v['number']}\nPhone: ${v['phone']}\nCNIC: ${v['cnic']}'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  void _showTotalCombinedLedger() {
    double grandTotalKiraya = 0;
    double grandTotalKharcha = 0;
    double grandTotalDriverPaid = 0;

    for (var v in vehicles) {
      for (var t in v['trips']) {
        grandTotalKiraya += (t['income'] ?? 0);
        grandTotalKharcha += (t['expense'] ?? 0);
      }
      for (var p in v['driverPayments']) {
        grandTotalDriverPaid += (p['amount'] ?? 0);
      }
    }

    double grandNetProfit = grandTotalKiraya - grandTotalKharcha - grandTotalDriverPaid;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ALL VEHICLES TOTAL LEDGER'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Total Active Vehicles'),
              trailing: Text('${vehicles.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Kiraya (All):'), Text('Rs. $grandTotalKiraya', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Kharcha (All):'), Text('Rs. $grandTotalKharcha', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Driver Paid (All):'), Text('Rs. $grandTotalDriverPaid', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.green.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GRAND NET PROFIT:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rs. $grandNetProfit', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            )
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.print), onPressed: () {}),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  void _showFuelRatesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Wise Fuel Rates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fuelRates.map((f) {
            return ListTile(
              tileColor: f['changed'] ? Colors.yellow.shade100 : null,
              title: Text('${f['location']} ${f['changed'] ? "(Rate Changed!)" : ""}'),
              subtitle: Text('Petrol: Rs.${f['petrol']} | Diesel: Rs.${f['diesel']}\nUpdated: ${f['updated']}'),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  void _openRecycleBin() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              const Text('Recycle Bin (Deleted Items)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: recycleBin.isEmpty
                    ? const Center(child: Text('Recycle bin is empty'))
                    : ListView.builder(
                        itemCount: recycleBin.length,
                        itemBuilder: (c, idx) => ListTile(
                          title: Text(recycleBin[idx]['number'] ?? 'Deleted Item'),
                          trailing: IconButton(
                            icon: const Icon(Icons.restore),
                            onPressed: () {
                              setState(() {
                                vehicles.add(recycleBin[idx]);
                                recycleBin.removeAt(idx);
                              });
                              setModalState(() {});
                            },
                          ),
                        ),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _addVehicleDialog() {
    final numCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cnicCtrl = TextEditingController();
    String selectedType = 'Company/Factory';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Vehicle & Driver'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Driver Phone Number')),
              TextField(controller: cnicCtrl, decoration: const InputDecoration(labelText: 'Driver CNIC / License')),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: ['Company/Factory', 'School', 'Tour/Private'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedType = val;
                },
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numCtrl.text.isNotEmpty) {
                setState(() {
                  vehicles.add({
                    'id': DateTime.now().toString(),
                    'number': numCtrl.text,
                    'driver': driverCtrl.text,
                    'phone': phoneCtrl.text,
                    'cnic': cnicCtrl.text,
                    'type': selectedType,
                    'fixedSalary': 25000.0,
                    'trips': [],
                    'driverPayments': [],
                    'oilChangeKm': 0,
                    'nextOilChangeKm': 5000,
                    'fuelAverage': 10.0,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _editVehicleDialog(int index) {
    final driverCtrl = TextEditingController(text: vehicles[index]['driver']);
    final phoneCtrl = TextEditingController(text: vehicles[index]['phone']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${vehicles[index]['number']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                recycleBin.add(vehicles[index]);
                vehicles.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete to Bin', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                vehicles[index]['driver'] = driverCtrl.text;
                vehicles[index]['phone'] = phoneCtrl.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          )
        ],
      ),
    );
  }

  void _openGariSinglePageLedger(Map<String, dynamic> gari) {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => SingleLedgerPage(gari: gari)));
  }
}

class SingleLedgerPage extends StatefulWidget {
  final Map<String, dynamic> gari;
  const SingleLedgerPage({super.key, required this.gari});

  @override
  State<SingleLedgerPage> createState() => _SingleLedgerPageState();
}

class _SingleLedgerPageState extends State<SingleLedgerPage> {
  @override
  Widget build(BuildContext context) {
    double totalKiraya = 0;
    double totalKharcha = 0;
    for (var t in widget.gari['trips']) {
      totalKiraya += (t['income'] ?? 0);
      totalKharcha += (t['expense'] ?? 0);
    }

    double totalDriverPaid = 0;
    for (var p in widget.gari['driverPayments']) {
      totalDriverPaid += (p['amount'] ?? 0);
    }

    double netProfit = totalKiraya - totalKharcha - totalDriverPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gari['number']} Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Ledger',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing PDF for Printing...')));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Text('RASHID TOURS - ${widget.gari['number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Type: ${widget.gari['type']} | Driver: ${widget.gari['driver']} (${widget.gari['phone']})'),
                    Text('Oil Change Due At: ${widget.gari['nextOilChangeKm']} KM', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Kiraya:'), Text('Rs. $totalKiraya', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Kharcha (Fuel/Misc):'), Text('Rs. $totalKharcha', style: const TextStyle(color: Colors.red))]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Driver Advance/Paid:'), Text('Rs. $totalDriverPaid', style: const TextStyle(color: Colors.orange))]),
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.green.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SAFI BACHAT (NET PROFIT):', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rs. $netProfit', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
                        const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share / Print Single Page Ledger'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

  }
}
