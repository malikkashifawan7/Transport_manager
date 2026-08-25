import 'pdf_export_service.dart';
import 'excel_export_service.dart';

import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pdf_export_service.dart';

class FleetDashboard extends StatefulWidget {
  final String gariNo;
  const FleetDashboard({Key? key, required this.gariNo}) : super(key: key);

  @override
  _FleetDashboardState createState() => _FleetDashboardState();
}

class _FleetDashboardState extends State<FleetDashboard> {
  List<Map<String, dynamic>> _trips = [];
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('trips', where: 'vehicle_no = ?', whereArgs: [widget.gariNo]);
    
    double income = 0;
    double expense = 0;
    for (var item in data) {
      income += (item['total_income'] as num).toDouble();
      expense += (item['fuel_expense'] as num).toDouble();
    }

    setState(() {
      _trips = data;
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  // Edit Trip Dialog
  void _showEditDialog(Map<String, dynamic> trip) {
    TextEditingController categoryController = TextEditingController(text: trip['category']);
    TextEditingController incomeController = TextEditingController(text: trip['total_income'].toString());
    TextEditingController expenseController = TextEditingController(text: trip['fuel_expense'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit Entry #${trip['id']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: ['Factory', 'School', 'Contract', 'Local Tour', 'Advance Booking'].contains(categoryController.text) 
                  ? categoryController.text 
                  : 'Local Tour',
              items: ['Factory', 'School', 'Contract', 'Local Tour', 'Advance Booking']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => categoryController.text = v!,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            TextField(controller: incomeController, decoration: const InputDecoration(labelText: "Income (PKR)")),
            TextField(controller: expenseController, decoration: const InputDecoration(labelText: "Expense (PKR)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateTrip(trip['id'], {
                'category': categoryController.text,
                'total_income': double.tryParse(incomeController.text) ?? 0,
                'fuel_expense': double.tryParse(expenseController.text) ?? 0,
                'last_edited': DateTime.now().toString(),
              });
              Navigator.pop(context);
              _refreshData();
            },
            child: const Text("Save Changes"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double netProfit = _totalIncome - _totalExpense;

    return Scaffold(
      appBar: AppBar(title: Text("Gari ${widget.gariNo} Master Ledger")),
      body: Column(
        children: [
          // Summary Header
          Card(
            margin: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Total Income: Rs. ${_totalIncome.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    Text("Expense: Rs. ${_totalExpense.toStringAsFixed(0)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ]),
                  const Divider(),
                  Text("SAFI BACHAT: Rs. ${netProfit.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueDark)),
                ],
              ),
            ),
          ),

          // Ledger List with Edit, Print & Share Options
          Expanded(
            child: ListView.builder(
              itemCount: _trips.length,
              itemBuilder: (context, i) {
                final trip = _trips[i];
                return Card(
                  child: ListTile(
                    title: Text("${trip['category']} - ${trip['route_details'] ?? 'Route'}"),
                    subtitle: Text("Date: ${trip['trip_date']}\nIncome: Rs. ${trip['total_income']} | Expense: Rs. ${trip['fuel_expense']}"),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit Entry
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showEditDialog(trip),
                        ),
                        // Export PDF & Share
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.green),
                          onPressed: () {
                            PdfExportService.generateAndShareInvoice(
                              gariNo: widget.gariNo,
                              driverName: "Driver Ledger",
                              tourType: trip['category'],
                              totalAmount: (trip['total_income'] as num).toDouble(),
                              advance: (trip['advance_received'] as num).toDouble(),
                              expense: (trip['fuel_expense'] as num).toDouble(),
                              date: trip['trip_date'],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
