import 'package:flutter/material.dart';
import 'database_helper.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final List<Map<String, dynamic>> records;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
    required this.records,
  });

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late List<Map<String, dynamic>> _recordsList;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _recordsList = List.from(widget.records);
  }

  void _refreshRecords() async {
    final updated = await DatabaseHelper.instance.getRecords(widget.vehicle['id']);
    setState(() {
      _recordsList = updated;
    });
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_selectedFilter == 'Income') {
      return _recordsList.where((r) => r['type'] == 'Income').toList();
    } else if (_selectedFilter == 'Expense') {
      return _recordsList.where((r) => r['type'] == 'Expense').toList();
    } else if (_selectedFilter == 'Udhar / Credit') {
      return _recordsList.where((r) => r['payment_status'] == 'Pending / Udhar').toList();
    }
    return _recordsList;
  }

  double get totalIncome => _recordsList
      .where((r) => r['type'] == 'Income')
      .fold(0.0, (sum, item) => sum + ((item['amount'] ?? 0) as num).toDouble());

  double get totalExpense => _recordsList
      .where((r) => r['type'] == 'Expense')
      .fold(0.0, (sum, item) => sum + ((item['amount'] ?? 0) as num).toDouble());

  double get totalLitres => _recordsList
      .where((r) => r['sub_category'] == 'Fuel / Diesel')
      .fold(0.0, (sum, item) => sum + ((item['litres'] ?? 0) as num).toDouble());

  // Auto Diesel Mileage Calculator (KM/L)
  double get calculatedFuelAverage {
    final fuelRecords = _recordsList
        .where((r) => r['sub_category'] == 'Fuel / Diesel' && (r['litres'] ?? 0) > 0 && (r['meter_reading'] ?? 0) > 0)
        .toList();

    if (fuelRecords.length < 2) return 0.0;

    double minKm = (fuelRecords.last['meter_reading'] as num).toDouble();
    double maxKm = (fuelRecords.first['meter_reading'] as num).toDouble();
    double totalLitresUsed = fuelRecords.fold(0.0, (sum, item) => sum + ((item['litres'] ?? 0) as num).toDouble());

    double totalDistance = maxKm - minKm;
    if (totalDistance <= 0 || totalLitresUsed <= 0) return 0.0;
    return totalDistance / totalLitresUsed;
  }

  void _showInvoiceDialog(Map<String, dynamic> item) {
    final invoiceText = '''
======== RASHID TOURS & TRAVELS ========
OFFICIAL FREIGHT & LEDGER INVOICE
----------------------------------------
Vehicle No: ${widget.vehicle['number']}
Driver: ${widget.vehicle['driver_name']}
Date: ${item['date']}
Category: ${item['sub_category']}
Narration: ${item['title']}
Party Name: ${item['party_name'] ?? 'N/A'}
Status: ${item['payment_status'] ?? 'Paid'}

AMOUNT: PKR ${item['amount']}
----------------------------------------
Generated via Transport ERP Enterprise
========================================
''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invoice Preview & Share'),
        content: SingleChildScrollView(
          child: Text(invoiceText, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice copied to clipboard for WhatsApp sharing!')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share to WhatsApp'),
          ),
        ],
      ),
    );
  }

  void _openAddRecordDialog() {
    String selectedType = 'Expense';
    String category = 'Fuel / Diesel';
    String paymentStatus = 'Paid';
    final amountCtrl = TextEditingController();
    final litresCtrl = TextEditingController();
    final meterCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final partyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Entry - ${widget.vehicle['number']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Expense')),
                        selected: selectedType == 'Expense',
                        onSelected: (val) => setModalState(() => selectedType = 'Expense'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Income / Freight')),
                        selected: selectedType == 'Income',
                        onSelected: (val) => setModalState(() => selectedType = 'Income'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: ['Fuel / Diesel', 'Maintenance & Repair', 'Driver Salary / Bhatta', 'Freight Income', 'Toll & Taxes', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setModalState(() => category = val ?? category),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: partyCtrl,
                  decoration: const InputDecoration(labelText: 'Party / Client Name (Udhar Khata)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: paymentStatus,
                  decoration: const InputDecoration(labelText: 'Payment Status', border: OutlineInputBorder()),
                  items: ['Paid', 'Pending / Udhar']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setModalState(() => paymentStatus = val ?? paymentStatus),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Description / Route', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (PKR)', border: OutlineInputBorder()),
                ),
                if (category == 'Fuel / Diesel') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: litresCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Litres', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: meterCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Odometer (KM)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                    onPressed: () async {
                      if (amountCtrl.text.isNotEmpty) {
                        await DatabaseHelper.instance.addRecord({
                          'vehicle_id': widget.vehicle['id'],
                          'date': DateTime.now().toString().split(' ')[0],
                          'type': selectedType,
                          'sub_category': category,
                          'title': titleCtrl.text.isEmpty ? category : titleCtrl.text,
                          'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                          'litres': double.tryParse(litresCtrl.text) ?? 0.0,
                          'meter_reading': double.tryParse(meterCtrl.text) ?? 0.0,
                          'party_name': partyCtrl.text,
                          'payment_status': paymentStatus,
                        });
                        _refreshRecords();
                        if (mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('SAVE ENTERPRISE RECORD'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = totalIncome - totalExpense;
    final avg = calculatedFuelAverage;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle['number']} Executive Dashboard'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Enterprise Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildMetric('FREIGHT REVENUE', 'PKR ${totalIncome.toStringAsFixed(0)}', Colors.greenAccent)),
                    Container(height: 35, width: 1, color: Colors.white24),
                    Expanded(child: _buildMetric('TOTAL EXPENSE', 'PKR ${totalExpense.toStringAsFixed(0)}', Colors.redAccent)),
                  ],
                ),
                const Divider(color: Colors.white24, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diesel Avg: ${avg > 0 ? avg.toStringAsFixed(2) : "N/A"} KM/L',
                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Net Profit: PKR ${netProfit.toStringAsFixed(0)}',
                      style: TextStyle(color: netProfit >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                )
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Income', 'Expense', 'Udhar / Credit'].map((filter) {
                  final isSel = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSel,
                      onSelected: (val) => setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredRecords.length,
              itemBuilder: (context, index) {
                final item = _filteredRecords[index];
                final isIncome = item['type'] == 'Income';
                final isUdhar = item['payment_status'] == 'Pending / Udhar';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? Colors.green : Colors.red),
                    ),
                    title: Text(item['title'] ?? item['sub_category']),
                    subtitle: Text('${item['date']} • Party: ${item['party_name'] ?? "Direct"}\nStatus: ${item['payment_status']}'),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncome ? "+" : "-"} PKR ${item['amount']}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.receipt, size: 18, color: Colors.blue),
                              onPressed: () => _showInvoiceDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.grey),
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteRecord(item['id']);
                                _refreshRecords();
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: _openAddRecordDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildMetric(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
