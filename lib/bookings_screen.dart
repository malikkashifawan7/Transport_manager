import 'package:flutter/material.dart';
import 'database_helper.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() async {
    final data = await DatabaseHelper.instance.fetchAll('bookings');
    setState(() {
      _bookings = data;
    });
  }

  void _addBookingDialog({Map<String, dynamic>? booking}) {
    final partyController = TextEditingController(text: booking?['partyName']);
    final phoneController = TextEditingController(text: booking?['phone']);
    final routeController = TextEditingController(text: booking?['route']);
    final vehicleController = TextEditingController(text: booking?['vehicleNumber']);
    final totalController = TextEditingController(text: booking != null ? booking['totalAmount'].toString() : '');
    final advanceController = TextEditingController(text: booking != null ? booking['advance'].toString() : '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(booking == null ? 'New Party Booking' : 'Edit Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: partyController, decoration: const InputDecoration(labelText: 'Party Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
              TextField(controller: routeController, decoration: const InputDecoration(labelText: 'Route (e.g. Lahore to Multan)')),
              TextField(controller: vehicleController, decoration: const InputDecoration(labelText: 'Vehicle Number')),
              TextField(controller: totalController, decoration: const InputDecoration(labelText: 'Total Amount'), keyboardType: TextInputType.number),
              TextField(controller: advanceController, decoration: const InputDecoration(labelText: 'Advance Received'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final total = double.tryParse(totalController.text) ?? 0.0;
              final adv = double.tryParse(advanceController.text) ?? 0.0;
              final data = {
                'partyName': partyController.text,
                'phone': phoneController.text,
                'route': routeController.text,
                'vehicleNumber': vehicleController.text,
                'totalAmount': total,
                'advance': adv,
                'balance': total - adv,
                'date': DateTime.now().toString().split(' ')[0],
              };

              if (booking == null) {
                await DatabaseHelper.instance.insertRecord('bookings', data);
              } else {
                await DatabaseHelper.instance.updateRecord('bookings', data, booking['id']);
              }
              Navigator.pop(context);
              _loadBookings();
            },
            child: const Text('Save Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Bookings'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _bookings.isEmpty
          ? const Center(child: Text('Koi Booking nahi hai. (+) button dabain.'))
          : ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final item = _bookings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(item['partyName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Route: ${item['route']}\nGari: ${item['vehicleNumber']} | Phone: ${item['phone']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total: Rs. ${item['totalAmount']}', style: const TextStyle(fontSize: 12)),
                        Text('Advance: Rs. ${item['advance']}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                        Text('Balance: Rs. ${item['balance']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    onTap: () => _addBookingDialog(booking: item),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _addBookingDialog(),
      ),
    );
  }
}
