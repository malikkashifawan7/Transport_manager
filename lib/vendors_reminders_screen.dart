import 'package:flutter/material.dart';
import 'database_helper.dart';

class VendorsRemindersScreen extends StatefulWidget {
  const VendorsRemindersScreen({Key? key}) : super(key: key);

  @override
  _VendorsRemindersScreenState createState() => _VendorsRemindersScreenState();
}

class _VendorsRemindersScreenState extends State<VendorsRemindersScreen> {
  List<Map<String, dynamic>> vendors = [];
  List<Map<String, dynamic>> reminders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final vData = await DatabaseHelper.instance.getVendors();
    final rData = await DatabaseHelper.instance.getReminders();
    setState(() {
      vendors = vData;
      reminders = rData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vendors & Reminders'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.store), text: 'Vendors Khata'),
              Tab(icon: Icon(Icons.alarm), text: 'Reminders & Alerts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Vendors List
            vendors.isEmpty
                ? const Center(child: Text('No Vendors Added'))
                : ListView.builder(
                    itemCount: vendors.length,
                    itemBuilder: (context, index) {
                      final item = vendors[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(item['name'] ?? ''),
                        subtitle: Text('Shop: ${item['shop_name'] ?? "N/A"} | Phone: ${item['phone'] ?? "N/A"}'),
                        trailing: Text(
                          'Rs. ${item['udhar_balance'] ?? 0}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),

            // Reminders List
            reminders.isEmpty
                ? const Center(child: Text('No Reminders Set'))
                : ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final item = reminders[index];
                      return ListTile(
                        leading: const Icon(Icons.notifications_active, color: Colors.orange),
                        title: Text(item['title'] ?? ''),
                        subtitle: Text('Due: ${item['due_date'] ?? "N/A"}'),
                        trailing: Chip(label: Text(item['type'] ?? 'General')),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
