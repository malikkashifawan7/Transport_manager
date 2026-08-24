import 'package:flutter/material.dart';
import 'database_helper.dart';

class VendorsRemindersScreen extends StatefulWidget {
  const VendorsRemindersScreen({super.key});

  @override
  State<VendorsRemindersScreen> createState() => _VendorsRemindersScreenState();
}

class _VendorsRemindersScreenState extends State<VendorsRemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> vendors = [];
  List<Map<String, dynamic>> reminders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() async {
    final v = await DatabaseHelper.instance.getVendors();
    final r = await DatabaseHelper.instance.getReminders();
    setState(() {
      vendors = v;
      reminders = r;
    });
  }

  void _showAddEditVendorDialog([Map<String, dynamic>? vendor]) {
    final nameController = TextEditingController(text: vendor?['name'] ?? '');
    final phoneController = TextEditingController(text: vendor?['phone'] ?? '');
    final typeController = TextEditingController(text: vendor?['type'] ?? 'Mechanic');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(vendor == null ? 'Add Vendor' : 'Edit Vendor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Vendor Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Type (e.g. Workshop, Fuel)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final data = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'type': typeController.text,
                  'balance': vendor?['balance'] ?? 0.0,
                };
                if (vendor == null) {
                  await DatabaseHelper.instance.addVendor(data);
                } else {
                  await DatabaseHelper.instance.updateVendor(vendor['id'], data);
                }
                _loadData();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddEditReminderDialog([Map<String, dynamic>? reminder]) {
    final titleController = TextEditingController(text: reminder?['title'] ?? '');
    final dateController = TextEditingController(text: reminder?['date'] ?? DateTime.now().toString().split(' ')[0]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(reminder == null ? 'Add Reminder' : 'Edit Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Reminder Title')),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final data = {
                  'title': titleController.text,
                  'date': dateController.text,
                  'status': reminder?['status'] ?? 'Pending',
                };
                if (reminder == null) {
                  await DatabaseHelper.instance.addReminder(data);
                } else {
                  await DatabaseHelper.instance.updateReminder(reminder['id'], data);
                }
                _loadData();
                if (mounted) Navigator.pop(context);
              }
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
        title: const Text('Vendors & Reminders'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Vendors Khata'),
            Tab(icon: Icon(Icons.alarm), text: 'Reminders & Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Vendors Tab
          vendors.isEmpty
              ? const Center(child: Text('No Vendors Added'))
              : ListView.builder(
                  itemCount: vendors.length,
                  itemBuilder: (context, index) {
                    final v = vendors[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(v['name']),
                      subtitle: Text('${v['type']} • ${v['phone']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddEditVendorDialog(v),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await DatabaseHelper.instance.deleteVendor(v['id']);
                              _loadData();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),

          // Reminders Tab
          reminders.isEmpty
              ? const Center(child: Text('No Reminders Set'))
              : ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final r = reminders[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.notifications)),
                      title: Text(r['title']),
                      subtitle: Text('Due: ${r['date']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddEditReminderDialog(r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await DatabaseHelper.instance.deleteReminder(r['id']);
                              _loadData();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddEditVendorDialog();
          } else {
            _showAddEditReminderDialog();
          }
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
