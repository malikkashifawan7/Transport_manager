import 'package:flutter/material.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final List<Map<String, String>> _maintenanceLogs = [
    {
      'type': 'Engine Oil & Filter Change',
      'cost': '18,500',
      'date': '2026-08-25',
      'workshop': 'Ustad Aslam Workshop',
    },
    {
      'type': 'Brake Pad Replacement',
      'cost': '12,000',
      'date': '2026-07-15',
      'workshop': 'Lahore Auto Workshop',
    },
  ];

  DateTime taxExpiry = DateTime.now().add(const Duration(days: 10));
  DateTime passingExpiry = DateTime.now().add(const Duration(days: 45));
  DateTime routePermitExpiry = DateTime.now().subtract(const Duration(days: 3));

  Color _getStatusColor(DateTime expiryDate) {
    final difference = expiryDate.difference(DateTime.now()).inDays;
    if (difference < 0) return Colors.red;
    if (difference <= 15) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText(DateTime expiryDate) {
    final difference = expiryDate.difference(DateTime.now()).inDays;
    if (difference < 0) return 'EXPIRED (${difference.abs()} days ago)';
    if (difference <= 15) return 'Expires in $difference days!';
    return 'Valid ($difference days left)';
  }

  void _addMaintenanceDialog() {
    final typeController = TextEditingController();
    final costController = TextEditingController();
    final workshopController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Maintenance Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Repair / Service Details')),
            TextField(controller: costController, decoration: const InputDecoration(labelText: 'Total Bill Amount (Rs.)'), keyboardType: TextInputType.number),
            TextField(controller: workshopController, decoration: const InputDecoration(labelText: 'Workshop / Mechanic Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (typeController.text.isNotEmpty && costController.text.isNotEmpty) {
                setState(() {
                  _maintenanceLogs.insert(0, {
                    'type': typeController.text,
                    'cost': costController.text,
                    'date': DateTime.now().toString().split(' ')[0],
                    'workshop': workshopController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save Bill'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.vehicle['name'] ?? 'Vehicle Details'),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.build), text: 'Maintenance'),
              Tab(icon: Icon(Icons.verified_user), text: 'Tax & Passing'),
              Tab(icon: Icon(Icons.info), text: 'Overview'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Scaffold(
              floatingActionButton: FloatingActionButton(
                backgroundColor: const Color(0xFF1A237E),
                onPressed: _addMaintenanceDialog,
                child: const Icon(Icons.add, color: Colors.white),
              ),
              body: _maintenanceLogs.isEmpty
                  ? const Center(child: Text('No maintenance records for this vehicle.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _maintenanceLogs.length,
                      itemBuilder: (context, index) {
                        final item = _maintenanceLogs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orangeAccent,
                              child: Icon(Icons.build, color: Colors.white),
                            ),
                            title: Text(item['type']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Workshop: ${item['workshop']}\nDate: ${item['date']}'),
                            trailing: Text(
                              'Rs. ${item['cost']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDocCard('Token Tax Expiry', taxExpiry),
                const SizedBox(height: 12),
                _buildDocCard('Fitness Passing Expiry', passingExpiry),
                const SizedBox(height: 12),
                _buildDocCard('Route Permit Expiry', routePermitExpiry),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Vehicle Number: ${widget.vehicle['number'] ?? widget.vehicle['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      Text('Model / Type: ${widget.vehicle['type'] ?? 'AC Bus / Coaster'}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Assigned Driver: ${widget.vehicle['driver'] ?? 'Ustad Ali'}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Current Status: ${widget.vehicle['status'] ?? 'Available'}', style: TextStyle(fontSize: 16, color: widget.vehicle['status'] == 'On Trip' ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(String title, DateTime expiryDate) {
    final color = _getStatusColor(expiryDate);
    final statusText = _getStatusText(expiryDate);

    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.verified, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Expiry Date: ${expiryDate.toString().split(' ')[0]}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
    );
  }
}
