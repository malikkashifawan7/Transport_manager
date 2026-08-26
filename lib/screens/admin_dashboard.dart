import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/app_services.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console - Awan Brothers'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: DatabaseService().getAllBookings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final bookings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (ctx, i) {
              final b = bookings[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(b.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Chip(label: Text(b.status.name.toUpperCase())),
                        ],
                      ),
                      Text('Item: ${b.itemTitle}'),
                      Text('Route: ${b.pickupLocation} ➔ ${b.dropLocation}'),
                      Text('Contact: ${b.phone} | WA: ${b.whatsapp}'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () => ActionService.makeCall(b.phone),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat, color: Colors.teal),
                            onPressed: () => ActionService.openWhatsApp(b.whatsapp, 'Hi ${b.customerName}, regarding your booking for ${b.itemTitle}:'),
                          ),
                          PopupMenuButton<BookingStatus>(
                            onSelected: (status) {
                              DatabaseService().updateBookingStatus(b.id, status);
                            },
                            itemBuilder: (ctx) => BookingStatus.values
                                .map((status) => PopupMenuItem(
                                      value: status,
                                      child: Text(status.name.toUpperCase()),
                                    ))
                                .toList(),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

