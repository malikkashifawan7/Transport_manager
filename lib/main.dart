import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// ============================================================================
// 1. MAIN & INITIALIZATION (CRASH-PROOF)
// ============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // Is line ko comment kar dein
  runApp(const AwanBrothersToursApp());
}


class AwanBrothersToursApp extends StatelessWidget {
  const AwanBrothersToursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awan Brothers Tours & Travels',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFFFF6F00),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.dark,
          primary: const Color(0xFF3F51B5),
          secondary: const Color(0xFFFF8F00),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainNavigationHub(),
    );
  }
}

// ============================================================================
// 2. ENUMS & UTILITIES
// ============================================================================
enum BookingStatus { pending, confirmed, rejected, cancelled, completed }

class ActionService {
  static const String businessPhone = "+923000000000";
  static const String businessEmail = "info@awanbrothers.com";

  static Future<void> makeCall([String? phone]) async {
    final Uri url = Uri(scheme: 'tel', path: phone ?? businessPhone);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  static Future<void> openWhatsApp([String? phone, String? message]) async {
    final String target = phone ?? businessPhone;
    final String msg = message ?? "Hello Awan Brothers Tours & Travels, I have an inquiry.";
    final Uri url = Uri.parse("https://wa.me/$target?text=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> openMap() async {
    final Uri url = Uri.parse("https://maps.google.com/?q=Lahore,Pakistan");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

// ============================================================================
// 3. MAIN NAVIGATION HUB
// ============================================================================
class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    VehiclesScreen(),
    TourPackagesScreen(),
    MyBookingsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.directions_bus_outlined), selectedIcon: Icon(Icons.directions_bus), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Tours'),
          NavigationDestination(icon: Icon(Icons.confirmation_number_outlined), selectedIcon: Icon(Icons.confirmation_number), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'More'),
        ],
      ),
    );
  }
}


// ============================================================================
// 5. CUSTOMER HOME SCREEN (FIXED FOR BLANK SCREEN ISSUE)
// ============================================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awan Brothers Tours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explore Pakistan With Us',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Premium buses, luxury SUVs, and customized northern area packages.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ActionService.openWhatsApp(),
                    icon: const Icon(Icons.chat),
                    label: const Text('Quick WhatsApp Inquiry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  context,
                  Icons.call,
                  'Call Us',
                  Colors.green,
                  () => ActionService.makeCall(),
                ),
                _buildQuickActionButton(
                  context,
                  Icons.location_on,
                  'Location',
                  Colors.red,
                  () => ActionService.openMap(),
                ),
                _buildQuickActionButton(
                  context,
                  Icons.help_outline,
                  'FAQs',
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FAQScreen()),
                  ),
                ),
                _buildQuickActionButton(
                  context,
                  Icons.info_outline,
                  'About',
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Featured Header
            const Text(
              'Featured Vehicles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Safe StreamBuilder with Fallback UI
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('vehicles').limit(3).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.directions_bus, color: Colors.grey, size: 30),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Fleet items will appear here once added in Admin Panel.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return VehicleCard(id: doc.id, data: data);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


// ============================================================================
// 6. VEHICLES SCREEN & CARD
// ============================================================================
class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Fleet')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No vehicles added yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return VehicleCard(id: doc.id, data: doc.data() as Map<String, dynamic>);
            },
          );
        },
      ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const VehicleCard({super.key, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.directions_bus, size: 40, color: Color(0xFF1A237E)),
        ),
        title: Text(data['name'] ?? 'Vehicle Name', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Capacity: ${data['capacity'] ?? 'N/A'} Seats | Type: ${data['type'] ?? 'Standard'}'),
            const SizedBox(height: 2),
            Text('Price: PKR ${data['pricePerDay'] ?? '0'} / Day', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookingFormScreen(itemTitle: data['name'] ?? 'Vehicle Booking')),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
          child: const Text('Book'),
        ),
      ),
    );
  }
}

// ============================================================================
// 7. TOUR PACKAGES SCREEN
// ============================================================================
class TourPackagesScreen extends StatelessWidget {
  const TourPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tour Packages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('packages').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tour packages available at this time.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Center(child: Icon(Icons.landscape, size: 60, color: Colors.amber)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? 'Tour Title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Destination: ${data['destination'] ?? 'N/A'} (${data['duration'] ?? 'N/A'})'),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('PKR ${data['price'] ?? '0'} / Person', style: const TextStyle(fontSize: 16, color: Colors.indigo, fontWeight: FontWeight.bold)),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => BookingFormScreen(itemTitle: data['title'] ?? 'Tour Booking')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                                child: const Text('Book Package'),
                              ),
                            ],
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
      ),
    );
  }
}

// ============================================================================
// 8. BOOKING FORM SCREEN
// ============================================================================
class BookingFormScreen extends StatefulWidget {
  final String itemTitle;
  const BookingFormScreen({super.key, required this.itemTitle});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  final _passengersCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  DateTime? _travelDate;
  DateTime? _returnDate;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book: ${widget.itemTitle}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone / WhatsApp Number *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid phone number' : null,
              ),
              const SizedBox(height: 20),
              const Text('Travel Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pickupCtrl,
                decoration: const InputDecoration(labelText: 'Pickup Location *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter pickup location' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dropCtrl,
                decoration: const InputDecoration(labelText: 'Drop-off Location *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter drop-off location' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passengersCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Number of Passengers *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter passenger count' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _travelDate = picked);
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_travelDate == null ? 'Travel Date *' : DateFormat('dd/MM/yyyy').format(_travelDate!)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _travelDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _returnDate = picked);
                      },
                      icon: const Icon(Icons.event_repeat),
                      label: Text(_returnDate == null ? 'Return Date' : DateFormat('dd/MM/yyyy').format(_returnDate!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _instructionsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Special Instructions (Optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm & Submit Booking Request', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a travel date')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'itemTitle': widget.itemTitle,
        'customerName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'pickupLocation': _pickupCtrl.text.trim(),
        'dropLocation': _dropCtrl.text.trim(),
        'passengers': _passengersCtrl.text.trim(),
        'travelDate': Timestamp.fromDate(_travelDate!),
        'returnDate': _returnDate != null ? Timestamp.fromDate(_returnDate!) : null,
        'instructions': _instructionsCtrl.text.trim(),
        'status': BookingStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Booking Submitted!'),
            content: const Text('Your booking request has been submitted successfully. Awan Brothers management will review and contact you shortly.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
// ============================================================================
// 9. MY BOOKINGS SCREEN
// ============================================================================
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Booking History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String status = data['status'] ?? 'pending';

              Color statusColor = Colors.orange;
              if (status == 'confirmed') statusColor = Colors.green;
              if (status == 'rejected' || status == 'cancelled') statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(data['itemTitle'] ?? 'Booking', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Name: ${data['customerName']}\nPickup: ${data['pickupLocation']} ➔ Drop: ${data['dropLocation']}'),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: statusColor,
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

// ============================================================================
// 10. SETTINGS, FAQ, ABOUT, PRIVACY
// ============================================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Info')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Awan Brothers Tours'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Frequently Asked Questions (FAQ)'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Admin Dashboard Login'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('App Version: 1.0.0 (Production Release)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }
}

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Awan Brothers Tours & Travels is a leading transport management service operating across Pakistan. We specialize in intercity routes, wedding fleets, northern area tourism, and luxury car rentals.\n\nOur mission is to deliver safe, clean, reliable, and comfortable travel experiences with highly trained professional drivers.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
      ),
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          ExpansionTile(
            title: Text('How do I confirm my booking?'),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Once submitted, our team reviews your request and contacts you via WhatsApp or phone call for final confirmation.'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Are drivers included with vehicle rentals?'),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Yes, all our luxury coasters, vans, and SUVs come with experienced commercial drivers.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Awan Brothers Tours & Travels respects your privacy. We collect customer information such as name, phone number, and location strictly for processing travel booking requests.\n\nWe do not sell or share customer data with third-party advertisers.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}

// ============================================================================
// 11. ADMIN DASHBOARD & MANAGEMENT
// ============================================================================
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Color(0xFF1A237E)),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login to Admin Panel'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.indigo.shade50,
            child: const ListTile(
              leading: Icon(Icons.security, color: Color(0xFF1A237E)),
              title: Text('Authenticated Admin Access', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Manage vehicles, bookings and packages in real-time.'),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Colors.grey.shade100,
            leading: const Icon(Icons.list_alt, color: Colors.indigo),
            title: const Text('Manage Booking Requests'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageBookingsScreen())),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.grey.shade100,
            leading: const Icon(Icons.directions_bus, color: Colors.green),
            title: const Text('Add / Manage Fleet Vehicles'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddVehicleScreen())),
          ),
        ],
      ),
    );
  }
}

class AdminManageBookingsScreen extends StatelessWidget {
  const AdminManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Bookings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text('${data['itemTitle']} - ${data['customerName']}'),
                  subtitle: Text('Phone: ${data['phone']} | Status: ${data['status']}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({'status': 'confirmed'}),
                            child: const Text('Approve'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({'status': 'rejected'}),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminAddVehicleScreen extends StatefulWidget {
  const AdminAddVehicleScreen({super.key});

  @override
  State<AdminAddVehicleScreen> createState() => _AdminAddVehicleScreenState();
}

class _AdminAddVehicleScreenState extends State<AdminAddVehicleScreen> {
  final _nameCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Fleet Vehicle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Vehicle Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Vehicle Type (e.g. Bus, Coaster, Sedan)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _capacityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seating Capacity', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price Per Day (PKR)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('vehicles').add({
                  'name': _nameCtrl.text,
                  'type': _typeCtrl.text,
                  'capacity': _capacityCtrl.text,
                  'pricePerDay': _priceCtrl.text,
                });
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save Vehicle'),
            )
          ],
        ),
      ),
    );
  }
}
