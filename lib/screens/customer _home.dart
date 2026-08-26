import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../services/app_services.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const VehiclesListTab(),
    const PackagesListTab(),
    const MyBookingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awan Brothers Tours & Travels',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: () => ActionService.makeCall('+923000000000'), // Replace with business phone
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo[900],
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.card_travel), label: 'Packages'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Banner Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade900, Colors.indigo.shade600],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium Transport & Travel Services',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Comfortable buses, luxury SUVs, and custom tours across Pakistan.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Quick Contact Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => ActionService.makeCall('+923000000000'),
              icon: const Icon(Icons.call),
              label: const Text('Call Us'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
            ElevatedButton.icon(
              onPressed: () => ActionService.openWhatsApp('+923000000000', 'Hello Awan Brothers, I need a vehicle quote.'),
              icon: const Icon(Icons.chat),
              label: const Text('WhatsApp'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 25),

        const Text('Featured Fleet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        // Dynamic Fleet Overview
        StreamBuilder<List<VehicleModel>>(
          stream: DatabaseService().getVehicles(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final list = snapshot.data!;
            if (list.isEmpty) return const Text('No vehicles available currently.');
            
            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final v = list[i];
                  return Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: v.images.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: v.images.first, fit: BoxFit.cover, width: double.infinity)
                                  : Container(color: Colors.grey.shade300, child: const Icon(Icons.directions_bus, size: 50)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Seats: ${v.capacity} | Rs. ${v.pricePerDay}/day', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// Vehicle List Tab
class VehiclesListTab extends StatelessWidget {
  const VehiclesListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VehicleModel>>(
      stream: DatabaseService().getVehicles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final vehicles = snapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: vehicles.length,
          itemBuilder: (ctx, i) {
            final v = vehicles[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: v.images.isNotEmpty
                      ? CachedNetworkImage(imageUrl: v.images.first, width: 70, height: 70, fit: BoxFit.cover)
                      : Container(width: 70, height: 70, color: Colors.grey.shade300, child: const Icon(Icons.directions_bus)),
                ),
                title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Capacity: ${v.capacity} Persons\nPKR ${v.pricePerDay} / day'),
                isThreeLine: true,
                trailing: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingFormScreen(itemTitle: v.name, bookingType: 'vehicle', basePrice: v.pricePerDay))),
                  child: const Text('Book'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Package List Tab
class PackagesListTab extends StatelessWidget {
  const PackagesListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TourPackageModel>>(
      stream: DatabaseService().getPackages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final packages = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: packages.length,
          itemBuilder: (ctx, i) {
            final p = packages[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.images.isNotEmpty)
                    CachedNetworkImage(imageUrl: p.images.first, height: 150, width: double.infinity, fit: BoxFit.cover),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Destination: ${p.destination} (${p.durationDays} Days)'),
                        Text('PKR ${p.price}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingFormScreen(itemTitle: p.title, bookingType: 'tour', basePrice: p.price))),
                            child: const Text('Book Tour'),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// User My Bookings Tab
class MyBookingsTab extends StatelessWidget {
  const MyBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Standard User ID setup (Can be dynamically mapped to Auth ID)
    const String tempUserId = 'user_12345';

    return StreamBuilder<List<BookingModel>>(
      stream: DatabaseService().getUserBookings(tempUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final bookings = snapshot.data!;
        if (bookings.isEmpty) return const Center(child: Text('No bookings placed yet.'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (ctx, i) {
            final b = bookings[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(b.itemTitle ?? 'Booking #${b.id.substring(0, 5)}'),
                subtitle: Text('Pickup: ${b.pickupLocation}\nDate: ${DateFormat('dd MMM yyyy').format(b.startDate)}'),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(b.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                  backgroundColor: _getStatusColor(b.status),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return Colors.orange;
      case BookingStatus.confirmed: return Colors.green;
      case BookingStatus.rejected: return Colors.red;
      case BookingStatus.cancelled: return Colors.grey;
      case BookingStatus.completed: return Colors.blue;
    }
  }
}

