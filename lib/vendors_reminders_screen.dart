import 'package:flutter/material.dart';
import '../database_helper.dart';

class VendorsRemindersScreen extends StatefulWidget {
  const VendorsRemindersScreen({Key? key}) : super(key: key);

  @override
  State<VendorsRemindersScreen> createState() => _VendorsRemindersScreenState();
}

class _VendorsRemindersScreenState extends State<VendorsRemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final vData = await DatabaseHelper.instance.fetchAll('vendors');
    final bData = await DatabaseHelper.instance.fetchAll('bookings');
    setState(() {
      _vendors = vData;
      _bookings = bData;
      _isLoading = false;
    });
  }

  // --- Add Vendor / Shop Dialog ---
  void _addVendorDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vendor / Shop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Shop / Vendor Name')),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Category (e.g. Spare Parts, Mechanic, Fuel)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              await DatabaseHelper.instance.insertRecord('vendors', {
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
                'type': typeController.text.trim(),
                'total_jama': 0.0,
                'total_udhar': 0.0,
                'balance': 0.0,
              });
              if (mounted) Navigator.pop(context);
              _loadData();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Add Khata Transaction (Jama / Udhar Entry) ---
  void _addKhataTransactionDialog(Map<String, dynamic> vendor) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String transType = 'UDHAR'; // 'UDHAR' (Bill) or 'JAMA' (Payment)

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Khata Entry: ${vendor['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: transType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'UDHAR', child: Text('Udhar / Bill (Dena Hai)')),
                  DropdownMenuItem(value: 'JAMA', child: Text('Jama / Payment Given (Adayi)')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => transType = val);
                },
              ),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs)')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Details / Description')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0) return;

                double currentJama = (vendor['total_jama'] ?? 0.0) as double;
                double currentUdhar = (vendor['total_udhar'] ?? 0.0) as double;

                if (transType == 'JAMA') {
                  currentJama += amount;
                } else {
                  currentUdhar += amount;
                }

                double netBalance = currentUdhar - currentJama;

                await DatabaseHelper.instance.updateRecord('vendors', {
                  'total_jama': currentJama,
                  'total_udhar': currentUdhar,
                  'balance': netBalance,
                }, vendor['id']);

                if (mounted) Navigator.pop(context);
                _loadData();
              },
              child: const Text('Save Entry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Add Party Booking (Advance / Baqaya) Dialog ---
  void _addBookingDialog() {
    final customerController = TextEditingController();
    final phoneController = TextEditingController();
    final destController = TextEditingController();
    final totalController = TextEditingController();
    final advanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Party Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: customerController, decoration: const InputDecoration(labelText: 'Party / Customer Name')),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
              TextField(controller: destController, decoration: const InputDecoration(labelText: 'Route / Destination')),
              TextField(controller: totalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Fare (Kiraya)')),
              TextField(controller: advanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance Received')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () async {
              final total = double.tryParse(totalController.text) ?? 0.0;
              final advance = double.tryParse(advanceController.text) ?? 0.0;
              final baqaya = total - advance;

              await DatabaseHelper.instance.insertRecord('bookings', {
                'customer': customerController.text.trim(),
                'phone': phoneController.text.trim(),
                'destination': destController.text.trim(),
                'date': DateTime.now().toString().split(' ')[0],
                'total_amount': total,
                'advance_amount': advance,
                'baqaya_amount': baqaya,
                'status': baqaya <= 0 ? 'Completed' : 'Pending',
              });

              if (mounted) Navigator.pop(context);
              _loadData();
            },
            child: const Text('Save Booking', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Udhar Khata & Bookings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Vendors / Udhar'),
            Tab(icon: Icon(Icons.book_online), text: 'Party Bookings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Vendor Udhar Tab
                _vendors.isEmpty
                    ? const Center(child: Text('No Vendor or Shop Khata added.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _vendors.length,
                        itemBuilder: (context, i) {
                          final v = _vendors[i];
                          final balance = (v['balance'] ?? 0.0) as double;
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              title: Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Total Udhar: Rs. ${v['total_udhar'] ?? 0}\nTotal Jama: Rs. ${v['total_jama'] ?? 0}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Baqaya: Rs. $balance',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: balance > 0 ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('+ Tap to Add Entry', style: TextStyle(fontSize: 10, color: Colors.blue)),
                                ],
                              ),
                              onTap: () => _addKhataTransactionDialog(v),
                            ),
                          );
                        },
                      ),

                // Party Bookings Tab
                _bookings.isEmpty
                    ? const Center(child: Text('No Party Bookings found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _bookings.length,
                        itemBuilder: (context, i) {
                          final b = _bookings[i];
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              title: Text('${b['customer']} (${b['destination'] ?? ''})', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Total: Rs. ${b['total_amount']} | Advance: Rs. ${b['advance_amount']}'),
                              trailing: Text(
                                'Baqaya: Rs. ${b['baqaya_amount']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: () {
          if (_tabController.index == 0) {
            _addVendorDialog();
          } else {
            _addBookingDialog();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
