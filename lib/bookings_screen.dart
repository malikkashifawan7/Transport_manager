import 'package:flutter/material.dart';
import 'database_helper.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _totalController = TextEditingController();
  final _advanceController = TextEditingController();
  final _vehicleController = TextEditingController();
  
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final list = await DatabaseHelper.instance.fetchAll('bookings');
    setState(() => _bookings = list);
  }

  Future<void> _addBooking() async {
    if (_nameController.text.isEmpty || _totalController.text.isEmpty) return;

    double total = double.tryParse(_totalController.text) ?? 0.0;
    double advance = double.tryParse(_advanceController.text) ?? 0.0;
    double remaining = total - advance;
    String dateStr = _selectedDate != null 
        ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
        : DateTime.now().toString().split(' ')[0];

    await DatabaseHelper.instance.insertRecord('bookings', {
      'customerName': _nameController.text,
      'phone': _phoneController.text,
      'totalAmount': total,
      'advanceAmount': advance,
      'remainingAmount': remaining,
      'bookingDate': dateStr,
      'vehicleNo': _vehicleController.text,
    });

    _nameController.clear();
    _phoneController.clear();
    _totalController.clear();
    _advanceController.clear();
    _vehicleController.clear();
    _selectedDate = null;

    if (mounted) Navigator.pop(context);
    _loadBookings();
  }

  void _showAddBookingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Party Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Party / Customer Name', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _vehicleController, decoration: const InputDecoration(labelText: 'Vehicle Number (e.g. LES-1234)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _totalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Amount (Rs.)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _advanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance Received (Rs.)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(_selectedDate == null 
                          ? 'Booking Date: Not Set' 
                          : 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() => _selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Pick Date'),
                    )
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addBooking,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                    child: const Text('Save Booking Record'),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          ? const Center(child: Text('No party bookings added yet.'))
          : ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final b = _bookings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(b['customerName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Vehicle: ${b['vehicleNo']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text('Phone: ${b['phone']} | Date: ${b['bookingDate']}', style: const TextStyle(color: Colors.grey)),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total: Rs. ${b['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('Advance: Rs. ${b['advanceAmount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            Text('Remaining: Rs. ${b['remainingAmount']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookingDialog,
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
