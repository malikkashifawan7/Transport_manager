import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  bool isLoggedIn = false;
  final TextEditingController pinCtrl = TextEditingController();
  final String appPin = "1234"; // Default PIN

  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> driverPayments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vehicles = List<Map<String, dynamic>>.from(json.decode(prefs.getString('rt_vehicles') ?? '[]'));
      bookings = List<Map<String, dynamic>>.from(json.decode(prefs.getString('rt_bookings') ?? '[]'));
      driverPayments = List<Map<String, dynamic>>.from(json.decode(prefs.getString('rt_payments') ?? '[]'));
    });
  }

  Future<void> _saveData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  void _addVehicleDialog() {
    final numCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Gari / Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Gari Number (e.g. 1054)')),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Driver Mobile Number')),
            TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Monthly Salary / Dihari'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (numCtrl.text.isNotEmpty) {
                setState(() {
                  vehicles.add({
                    'number': numCtrl.text,
                    'driver': driverCtrl.text,
                    'phone': phoneCtrl.text,
                    'salary': salaryCtrl.text,
                  });
                });
                _saveData('rt_vehicles', vehicles);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _addTripDialog(String vNum, StateSetter setLedgerState) {
    final partyCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final fareCtrl = TextEditingController();
    final expCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Trip: $vNum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: partyCtrl, decoration: const InputDecoration(labelText: 'Party Name')),
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route (e.g. Lahore to Multan)')),
            TextField(controller: fareCtrl, decoration: const InputDecoration(labelText: 'Total Fare (Kiraya)'), keyboardType: TextInputType.number),
            TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Diesel / Kharcha'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                bookings.add({
                  'vehicle': vNum,
                  'party': partyCtrl.text,
                  'route': routeCtrl.text,
                  'fare': fareCtrl.text,
                  'exp': expCtrl.text,
                  'date': DateTime.now().toString().split(' ')[0],
                });
              });
              _saveData('rt_bookings', bookings);
              setLedgerState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save Trip'),
          )
        ],
      ),
    );
  }

  void _addDriverPaymentDialog(String vNum, StateSetter setLedgerState) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Driver Payment / Advance: $vNum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (Rs.)'), keyboardType: TextInputType.number),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Detail / Advance Note')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                driverPayments.add({
                  'vehicle': vNum,
                  'amount': amountCtrl.text,
                  'note': noteCtrl.text,
                  'date': DateTime.now().toString().split(' ')[0],
                });
              });
              _saveData('rt_payments', driverPayments);
              setLedgerState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save Payment'),
          )
        ],
      ),
    );
  }
  void _openGariSinglePageLedger(Map<String, dynamic> v) {
    String vNum = v['number'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setLedgerState) {
            var vTrips = bookings.where((b) => b['vehicle'] == vNum).toList();
            var vPay = driverPayments.where((p) => p['vehicle'] == vNum).toList();

            double totalFare = vTrips.fold(0, (s, i) => s + (double.tryParse(i['fare'] ?? '0') ?? 0));
            double totalExp = vTrips.fold(0, (s, i) => s + (double.tryParse(i['exp'] ?? '0') ?? 0));
            double totalPaidToDriver = vPay.fold(0, (s, i) => s + (double.tryParse(i['amount'] ?? '0') ?? 0));
            
            // Total Bachat = Total Fare - (Expenses + Driver Payments)
            double bachat = totalFare - (totalExp + totalPaidToDriver);

            return Scaffold(
              appBar: AppBar(
                title: Text('Gari $vNum Ledger'),
                backgroundColor: Colors.blueAccent,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SINGLE PAGE SUMMARY BOX
                    Card(
                      color: Colors.blue.shade50,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text('RASHID TOURS - GARI $vNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Driver: ${v['driver']} | Phone: ${v['phone']}'),
                            Text('Fixed Salary: Rs. ${v['salary'] ?? '0'}'),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Kiraya:', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Rs. $totalFare', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Kharcha (Fuel/Misc):'),
                                Text('Rs. $totalExp', style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Driver Advance/Paid:'),
                                Text('Rs. $totalPaidToDriver', style: const TextStyle(color: Colors.orange)),
                              ],
                            ),
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.green.shade100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('SAFI BACHAT (NET PROFIT):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('Rs. $bachat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _addTripDialog(vNum, setLedgerState),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Trip'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: () => _addDriverPaymentDialog(vNum, setLedgerState),
                          icon: const Icon(Icons.money, color: Colors.white),
                          label: const Text('Driver Pay/Advance', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 45)),
                      onPressed: () => _sendWhatsAppDirect(vNum, v, totalFare, totalExp, totalPaidToDriver, bachat),
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text('Share Ledger on Any WhatsApp Number', style: TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                    const SizedBox(height: 15),
                    const Text('TRIP HISTORY', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...vTrips.map((t) => ListTile(
                          title: Text('${t['party']} (${t['route']})'),
                          subtitle: Text('Date: ${t['date']} | Exp: Rs. ${t['exp']}'),
                          trailing: Text('Rs. ${t['fare']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        )),
                    const Divider(),
                    const Text('DRIVER PAYMENTS / ADVANCE HISTORY', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...vPay.map((p) => ListTile(
                          title: Text('Paid: Rs. ${p['amount']}'),
                          subtitle: Text('Note: ${p['note']} | Date: ${p['date']}'),
                          leading: const Icon(Icons.payment, color: Colors.orange),
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

  void _sendWhatsAppDirect(String vNum, Map<String, dynamic> v, double fare, double exp, double driverPaid, double bachat) {
    final numCtrl = TextEditingController(text: v['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Any WhatsApp Number'),
        content: TextField(
          controller: numCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'e.g. 03001234567'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              String text = "*Rashid Tours - Gari $vNum Summary*\n\n"
                  "Driver: ${v['driver']}\n"
                  "Total Fare: Rs. $fare\n"
                  "Total Kharcha: Rs. $exp\n"
                  "Driver Paid/Advance: Rs. $driverPaid\n"
                  "------------------------------\n"
                  "*Net Bachat:* Rs. $bachat\n\n"
                  "Shukriya!";

              final Uri url = Uri.parse("https://wa.me/${numCtrl.text}?text=${Uri.encodeComponent(text)}");
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
                }
              }
            },
            child: const Text('Send WhatsApp'),
          )
        ],
      ),
    );
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Urdu / English Guide'),
        content: const SingleChildScrollView(
          child: Text(
            "English:\n1. Default PIN is 1234.\n2. Tap + to add vehicle.\n3. Open vehicle to view single page ledger & net profit.\n4. Share ledger to any WhatsApp number directly.\n\n"
            "اردو رہنمائی:\n1. ایپ کا خفیہ پن 1234 ہے۔\n2. نئی گاڑی شامل کرنے کے لیے + کا بٹن دبائیں۔\n3. گاڑی پر کلک کر کے ایک ہی صفحے پر سارا حساب اور بچت دیکھیں۔\n4. کسی بھی واٹس ایپ نمبر پر رپورٹ بھیجیں۔",
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
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Enter Password / PIN (1234)'),
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
        title: const Text('Rashid Tours & Travels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showGuideDialog,
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
                  title: Text(vehicles[i]['number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Driver: ${vehicles[i]['driver']} | Phone: ${vehicles[i]['phone']}'),
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
}
  void _openGariSinglePageLedger(Map<String, dynamic> v) {
    String vNum = v['number'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setLedgerState) {
            var vTrips = bookings.where((b) => b['vehicle'] == vNum).toList();
            var vPay = driverPayments.where((p) => p['vehicle'] == vNum).toList();

            double totalFare = vTrips.fold(0, (s, i) => s + (double.tryParse(i['fare'] ?? '0') ?? 0));
            double totalExp = vTrips.fold(0, (s, i) => s + (double.tryParse(i['exp'] ?? '0') ?? 0));
            double totalPaidToDriver = vPay.fold(0, (s, i) => s + (double.tryParse(i['amount'] ?? '0') ?? 0));
            
            // Total Bachat = Total Fare - (Expenses + Driver Payments)
            double bachat = totalFare - (totalExp + totalPaidToDriver);

            return Scaffold(
              appBar: AppBar(
                title: Text('Gari $vNum Ledger'),
                backgroundColor: Colors.blueAccent,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SINGLE PAGE SUMMARY BOX
                    Card(
                      color: Colors.blue.shade50,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text('RASHID TOURS - GARI $vNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Driver: ${v['driver']} | Phone: ${v['phone']}'),
                            Text('Fixed Salary: Rs. ${v['salary'] ?? '0'}'),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Kiraya:', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Rs. $totalFare', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Kharcha (Fuel/Misc):'),
                                Text('Rs. $totalExp', style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Driver Advance/Paid:'),
                                Text('Rs. $totalPaidToDriver', style: const TextStyle(color: Colors.orange)),
                              ],
                            ),
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.green.shade100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('SAFI BACHAT (NET PROFIT):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('Rs. $bachat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _addTripDialog(vNum, setLedgerState),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Trip'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: () => _addDriverPaymentDialog(vNum, setLedgerState),
                          icon: const Icon(Icons.money, color: Colors.white),
                          label: const Text('Driver Pay/Advance', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 45)),
                      onPressed: () => _sendWhatsAppDirect(vNum, v, totalFare, totalExp, totalPaidToDriver, bachat),
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text('Share Ledger on Any WhatsApp Number', style: TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                    const SizedBox(height: 15),
                    const Text('TRIP HISTORY', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...vTrips.map((t) => ListTile(
                          title: Text('${t['party']} (${t['route']})'),
                          subtitle: Text('Date: ${t['date']} | Exp: Rs. ${t['exp']}'),
                          trailing: Text('Rs. ${t['fare']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        )),
                    const Divider(),
                    const Text('DRIVER PAYMENTS / ADVANCE HISTORY', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...vPay.map((p) => ListTile(
                          title: Text('Paid: Rs. ${p['amount']}'),
                          subtitle: Text('Note: ${p['note']} | Date: ${p['date']}'),
                          leading: const Icon(Icons.payment, color: Colors.orange),
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

  void _sendWhatsAppDirect(String vNum, Map<String, dynamic> v, double fare, double exp, double driverPaid, double bachat) {
    final numCtrl = TextEditingController(text: v['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Any WhatsApp Number'),
        content: TextField(
          controller: numCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'e.g. 03001234567'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              String text = "*Rashid Tours - Gari $vNum Summary*\n\n"
                  "Driver: ${v['driver']}\n"
                  "Total Fare: Rs. $fare\n"
                  "Total Kharcha: Rs. $exp\n"
                  "Driver Paid/Advance: Rs. $driverPaid\n"
                  "------------------------------\n"
                  "*Net Bachat:* Rs. $bachat\n\n"
                  "Shukriya!";

              final Uri url = Uri.parse("https://wa.me/${numCtrl.text}?text=${Uri.encodeComponent(text)}");
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
                }
              }
            },
            child: const Text('Send WhatsApp'),
          )
        ],
      ),
    );
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Urdu / English Guide'),
        content: const SingleChildScrollView(
          child: Text(
            "English:\n1. Default PIN is 1234.\n2. Tap + to add vehicle.\n3. Open vehicle to view single page ledger & net profit.\n4. Share ledger to any WhatsApp number directly.\n\n"
            "اردو رہنمائی:\n1. ایپ کا خفیہ پن 1234 ہے۔\n2. نئی گاڑی شامل کرنے کے لیے + کا بٹن دبائیں۔\n3. گاڑی پر کلک کر کے ایک ہی صفحے پر سارا حساب اور بچت دیکھیں۔\n4. کسی بھی واٹس ایپ نمبر پر رپورٹ بھیجیں۔",
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
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Enter Password / PIN (1234)'),
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
        title: const Text('Rashid Tours & Travels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showGuideDialog,
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
                  title: Text(vehicles[i]['number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Driver: ${vehicles[i]['driver']} | Phone: ${vehicles[i]['phone']}'),
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
}
