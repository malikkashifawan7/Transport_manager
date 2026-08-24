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
    } else if (_selectedFilter == 'Fuel') {
      return _recordsList.where((r) => r['sub_category'] == 'Fuel / Diesel').toList();
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Ledger Entry - ${widget.vehicle['number']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedType = 'Expense'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'Expense' ? Colors.red.shade600 : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'EXPENSE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedType == 'Expense' ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedType = 'Income'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'Income' ? Colors.green.shade600 : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'INCOME / FREIGHT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedType == 'Income' ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Fuel / Diesel', 'Maintenance & Repair', 'Driver Salary / Bhatta', 'Toll & Taxes', 'Freight Income', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setModalState(() => category = val ?? category),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description / Narration',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (PKR)',
                    prefixText: 'PKR ',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (category == 'Fuel / Diesel') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: litresCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Fuel (Litres)',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: meterCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Odometer (KM)',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    child: const Text('SAVE ENTERPRISE RECORD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.vehicle['number']} Financial Dashboard', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating Ledger Report...')),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildMetricTile('TOTAL FREIGHT', 'PKR ${totalIncome.toStringAsFixed(0)}', Colors.greenAccent, Icons.trending_up)),
                    Container(height: 40, width: 1, color: Colors.white24),
                    Expanded(child: _buildMetricTile('TOTAL EXPENSES', 'PKR ${totalExpense.toStringAsFixed(0)}', Colors.redAccent, Icons.trending_down)),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_gas_station, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text('Total Diesel: ${totalLitres.toStringAsFixed(0)} Ltrs', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: netProfit >= 0 ? Colors.green.shade900.withOpacity(0.6) : Colors.red.shade900.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: netProfit >= 0 ? Colors.green : Colors.red),
                      ),
                      child: Text(
                        'Net Profit: PKR ${netProfit.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: netProfit >= 0 ? Colors.greenAccent : Colors.redAccent),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Income', 'Expense', 'Fuel'].map((filter) {
                  final isSel = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSel,
                      selectedColor: const Color(0xFF1E3A8A),
                      labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                      onSelected: (val) => setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _filteredRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No records found for "$_selectedFilter"', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final item = _filteredRecords[index];
                      final isIncome = item['type'] == 'Income';
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? item['sub_category'] ?? 'Transaction',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['date']} • ${item['sub_category']}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    if ((item['litres'] ?? 0) > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${item['litres']} Ltrs | Meter: ${item['meter_reading']} KM',
                                          style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isIncome ? "+" : "-"} PKR ${item['amount']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
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
        elevation: 4,
        onPressed: _openAddRecordDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Entry', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
