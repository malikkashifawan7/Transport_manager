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
      'trips': [
        {'id': 't1', 'title': 'Lahore to Multan', 'income': 20000.0, 'expense': 8000.0, 'date': '2026-08-22', 'category': 'Diesel & Toll'},
        {'id': 't2', 'title': 'Factory Shift', 'income': 15000.0, 'expense': 3000.0, 'date': '2026-08-21', 'category': 'Local'}
      ],
      'driverPayments': [
        {'id': 'p1', 'amount': 5000.0, 'note': 'Beti k leay Advance', 'date': '2026-08-22'}
      ],
      'oilChangeKm': 45000,
      'nextOilChangeKm': 50000,
      'fuelAverage': 12.5,
    }
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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
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
        title: const Text('ALL VEHICLES COMBINED LEDGER'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Vehicles: ${vehicles.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Kiraya:'), Text('Rs. $grandTotalKiraya', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Kharcha:'), Text('Rs. $grandTotalKharcha', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Driver Paid:'), Text('Rs. $grandTotalDriverPaid', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.green.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('NET PROFIT:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rs. $grandNetProfit', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            )
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _addVehicleDialog() {
    final numCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
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
                    'cnic': 'N/A',
                    'type': 'Company/Factory',
                    'trips': [],
                    'driverPayments': [],
                    'nextOilChangeKm': 50000,
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

  void _openGariSinglePageLedger(Map<String, dynamic> gari) {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => SingleLedgerPage(gari: gari))).then((_) {
      setState(() {});
    });
  }
}

class SingleLedgerPage extends StatefulWidget {
  final Map<String, dynamic> gari;
  const SingleLedgerPage({super.key, required this.gari});

  @override
  State<SingleLedgerPage> createState() => _SingleLedgerPageState();
}

class _SingleLedgerPageState extends State<SingleLedgerPage> {
  void _addTripDialog() {
    final titleCtrl = TextEditingController();
    final incomeCtrl = TextEditingController();
    final expenseCtrl = TextEditingController();
    String category = 'Diesel';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Trip / Route Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Route / Title (e.g. LHR to MLN)')),
                TextField(controller: incomeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Income / Kiraya (Rs.)')),
                TextField(controller: expenseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Expense / Fuel/Toll (Rs.)')),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  items: ['Diesel', 'Maintenance/Repairs', 'Toll Tax / Food', 'Other'].map((String val) {
                    return DropdownMenuItem<String>(value: val, child: Text(val));
                  }).toList(),
                  onChanged: (v) => setDlgState(() => category = v!),
                ),
                ListTile(
                  title: Text('Date: ${selectedDate.toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDlgState(() => selectedDate = picked);
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.gari['trips'].add({
                    'id': DateTime.now().toString(),
                    'title': titleCtrl.text.isEmpty ? 'Trip' : titleCtrl.text,
                    'income': double.tryParse(incomeCtrl.text) ?? 0.0,
                    'expense': double.tryParse(expenseCtrl.text) ?? 0.0,
                    'category': category,
                    'date': selectedDate.toString().split(' ')[0],
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add Entry'),
            )
          ],
        ),
      ),
    );
  }

  void _addDriverPaymentDialog() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Driver Payment / Advance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Paid (Rs.)')),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note / Reason (e.g. Khuraak, Salary)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.gari['driverPayments'].add({
                  'id': DateTime.now().toString(),
                  'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                  'note': noteCtrl.text.isEmpty ? 'Advance' : noteCtrl.text,
                  'date': DateTime.now().toString().split(' ')[0],
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save Payment'),
          )
        ],
      ),
    );
  }

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
        title: Text('${widget.gari['number']} Live Ledger'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Text('RASHID TOURS - ${widget.gari['number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Driver: ${widget.gari['driver']} (${widget.gari['phone']})'),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Kiraya (Income):'), Text('Rs. $totalKiraya', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))]),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Vehicle Kharcha:'), Text('Rs. $totalKharcha', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))]),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Driver Advance/Khuraak:'), Text('Rs. $totalDriverPaid', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16))]),
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.green.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SAFI BACHAT (NET PROFIT):', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rs. $netProfit', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    icon: const Icon(Icons.add_road),
                    label: const Text('+ Add Trip'),
                    onPressed: _addTripDialog,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    icon: const Icon(Icons.person_add),
                    label: const Text('+ Driver Kharcha'),
                    onPressed: _addDriverPaymentDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text('Trips & Routes Ledger:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            widget.gari['trips'].isEmpty
                ? const Padding(padding: EdgeInsets.all(10), child: Text('Koi trip add nahi hua.'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.gari['trips'].length,
                    itemBuilder: (c, idx) {
                      var trip = widget.gari['trips'][idx];
                      return Card(
                        child: ListTile(
                          title: Text('${trip['title']} (${trip['category']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Date: ${trip['date']}\nIncome: Rs.${trip['income']} | Expense: Rs.${trip['expense']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                widget.gari['trips'].removeAt(idx);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 15),
            const Text('Driver Advance / Khuraak Ledger:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            widget.gari['driverPayments'].isEmpty
                ? const Padding(padding: EdgeInsets.all(10), child: Text('Driver ko koi advance nahi diya gaya.'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.gari['driverPayments'].length,
                    itemBuilder: (c, idx) {
                    var p = widget.gari['driverPayments'][idx];
                      return Card(
                        color: Colors.orange.shade50,
                        child: ListTile(
                          title: Text('Rs. ${p['amount']} - ${p['note']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Date: ${p['date']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                                                        onPressed: () {
                              setState(() {
                                widget.gari['driverPayments'].removeAt(idx);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
