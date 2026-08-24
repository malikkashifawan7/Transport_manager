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

  double get totalIncome => _recordsList
      .where((r) => r['type'] == 'Income')
      .fold(0.0, (sum, item) => sum + ((item['amount'] ?? 0) as num).toDouble());

  double get totalExpense => _recordsList
      .where((r) => r['type'] == 'Expense')
      .fold(0.0, (sum, item) => sum + ((item['amount'] ?? 0) as num).toDouble());

  void _openAddRecordDialog() {
    String selectedType = 'Expense';
    String category = 'Fuel / Diesel';
    final amountCtrl = TextEditingController();
    final litresCtrl = TextEditingController();
    final meterCtrl = TextEditingController();
    final titleCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Entry - ${widget.vehicle['number']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Expense')),
                        selected: selectedType == 'Expense',
                        selectedColor: Colors.red.shade100,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedType = 'Expense');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Income / Freight')),
                        selected: selectedType == 'Income',
                        selectedColor: Colors.green.shade100,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedType = 'Income');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: ['Fuel / Diesel', 'Maintenance & Repair', 'Driver Salary / Bhatta', 'Toll & Taxes', 'Freight Income', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setModalState(() => category = val ?? category),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Description / Details', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (PKR)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                if (category == 'Fuel / Diesel') ...[
                  TextField(
                    controller: litresCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Fuel Litres', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: meterCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Odometer Reading (KM)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (amountCtrl.text.isNotEmpty) {
                        try {
                          await DatabaseHelper.instance.addRecord({
                            'vehicle_id': widget.vehicle['id'],
                            'date': DateTime.now().toString().split(' ')[0],
                            'type': selectedType,
                            'sub_category': category,
                            'title': titleCtrl.text.isEmpty ? category : titleCtrl.text,
                            'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                            'litres': double.tryParse(litresCtrl.text) ?? 0.0,
                            'meter_reading': double.tryParse(meterCtrl.text) ?? 0.0,
                          });
                          _refreshRecords();
                          if (mounted) Navigator.pop(ctx);
                        } catch (e) {
                          debugPrint("Save error: $e");
                        }
                      }
                    },
                    child: const Text('Save Entry'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle['number']} Ledger'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Income', 'PKR ${totalIncome.toStringAsFixed(0)}', Colors.green),
                _buildStatCard('Expense', 'PKR ${totalExpense.toStringAsFixed(0)}', Colors.red),
                _buildStatCard('Net Profit', 'PKR ${netProfit.toStringAsFixed(0)}', netProfit >= 0 ? Colors.green.shade800 : Colors.red.shade800),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _recordsList.isEmpty
                ? const Center(child: Text('No Ledger entries found. Tap + to add.'))
                : ListView.builder(
                    itemCount: _recordsList.length,
                    itemBuilder: (context, index) {
                      final item = _recordsList[index];
                      final isIncome = item['type'] == 'Income';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(item['title'] ?? item['sub_category'] ?? 'Entry'),
                          subtitle: Text('${item['date']} • ${item['sub_category']}'),
                          trailing: Text(
                            '${isIncome ? "+" : "-"} PKR ${item['amount']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        onPressed: _openAddRecordDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
