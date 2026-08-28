import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pdf_helper.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshBookings();
  }

  Future<void> _refreshBookings() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchAll('bookings');
    setState(() {
      _bookings = data;
      _isLoading = false;
    });
  }

  void _showBookingDialog({Map<String, dynamic>? booking}) {
    final customerController = TextEditingController(text: booking?['customer']);
    final phoneController = TextEditingController(text: booking?['phone']);
    final destController = TextEditingController(text: booking?['destination']);
    final dateController = TextEditingController(text: booking?['date']);
    final amountController = TextEditingController(text: booking?['amount']?.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(booking == null ? 'Add Booking' : 'Edit Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: customerController, decoration: const InputDecoration(labelText: 'Customer Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: destController, decoration: const InputDecoration(labelText: 'Destination')),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (e.g. 2026-08-28)')),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'customer': customerController.text,
                'phone': phoneController.text,
                'destination': destController.text,
                'date': dateController.text,
                'amount': double.tryParse(amountController.text) ?? 0.0,
                'status': 'Confirmed',
              };

              if (booking == null) {
                await DatabaseHelper.instance.insertRecord('bookings', data);
              } else {
                await DatabaseHelper.instance.updateRecord('bookings', data, booking['id']);
              }

              Navigator.pop(context);
              _refreshBookings();
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
        title: const Text('Party Bookings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(child: Text('No bookings added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final item = _bookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1A237E),
                          child: Icon(Icons.bookmark, color: Colors.white),
                        ),
                        title: Text(item['customer'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['destination']} | ${item['date']}\nAmount: Rs. ${item['amount']}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.indigo),
                              onPressed: () {
                                PdfHelper.generateBookingPdf(
                                  customerName: item['customer'] ?? '',
                                  phone: item['phone'] ?? '',
                                  destination: item['destination'] ?? '',
                                  date: item['date'] ?? '',
                                  amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showBookingDialog(booking: item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: () => _showBookingDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
