import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../services/app_services.dart';

class BookingFormScreen extends StatefulWidget {
  final String itemTitle;
  final String bookingType;
  final double basePrice;

  const BookingFormScreen({
    super.key,
    required this.itemTitle,
    required this.bookingType,
    required this.basePrice,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _passengersController = TextEditingController(text: '1');
  final _instructionsController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book ${widget.itemTitle}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter contact number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'WhatsApp Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pickupController,
                decoration: const InputDecoration(labelText: 'Pickup Location', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter pickup location' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dropController,
                decoration: const InputDecoration(labelText: 'Drop-off Destination', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter drop location' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
                  onPressed: _isSubmitting ? null : _submitBooking,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Booking Request', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final booking = BookingModel(
          id: '',
          userId: 'user_12345', // Default mapped auth user
          customerName: _nameController.text,
          phone: _phoneController.text,
          whatsapp: _whatsappController.text,
          itemTitle: widget.itemTitle,
          bookingType: widget.bookingType,
          startDate: _startDate,
          endDate: _endDate,
          pickupLocation: _pickupController.text,
          dropLocation: _dropController.text,
          passengers: int.tryParse(_passengersController.text) ?? 1,
          totalPrice: widget.basePrice,
          status: BookingStatus.pending,
          specialInstructions: _instructionsController.text,
          createdAt: DateTime.now(),
        );

        await DatabaseService().createBooking(booking);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking request sent successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place booking: $e')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

