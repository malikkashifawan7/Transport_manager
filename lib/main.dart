import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport Manager Pro',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AdvancedFleetScreen(gariNo: "1054"),
    );
  }
}

// --- DATABASE HELPER ---
class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;
  DBService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_pro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicle_no TEXT,
            category TEXT,
            route_details TEXT,
            total_income REAL,
            advance REAL,
            expense REAL,
            trip_date TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertTrip(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('trips', row);
  }

  Future<List<Map<String, dynamic>>> getTrips(String vehicleNo) async {
    final db = await instance.database;
    return await db.query('trips', where: 'vehicle_no = ?', whereArgs: [vehicleNo]);
  }

  Future<int> updateTrip(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('trips', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }
}

// --- MAIN ADVANCED SCREEN ---
class AdvancedFleetScreen extends StatefulWidget {
  final String gariNo;
  const AdvancedFleetScreen({Key? key, required this.gariNo}) : super(key: key);

  @override
  _AdvancedFleetScreenState createState() => _AdvancedFleetScreenState();
}

class _AdvancedFleetScreenState extends State<AdvancedFleetScreen> {
  List<Map<String, dynamic>> _trips = [];
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final data = await DBService.instance.getTrips(widget.gariNo);
    double income = 0;
    double expense = 0;
    for (var item in data) {
      income += (item['total_income'] as num).toDouble();
      expense += (item['expense'] as num).toDouble();
    }
    setState(() {
      _trips = data;
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  void _openGoogleMap(String route) async {
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(route)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _generatePDF(Map<String, dynamic> trip) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("TRANSPORT HISAB - OFFICIAL BILL INVOICE", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Vehicle No: ${trip['vehicle_no']}"),
            pw.Text("Category: ${trip['category']}"),
            pw.Text("Route / Details: ${trip['route_details']}"),
            pw.Text("Date: ${trip['trip_date']}"),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Description', 'Amount (PKR)'],
              data: [
                ['Total Income', trip['total_income'].toString()],
                ['Advance Received', trip['advance'].toString()],
                ['Expenses', trip['expense'].toString()],
                ['Net Profit', (trip['total_income'] - trip['expense']).toString()],
              ],
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Invoice_${trip['id']}.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Bill Invoice for Gari ${widget.gariNo}');
  }

  void _showTripDialog({Map<String, dynamic>? existingTrip}) {
    String selectedCategory = existingTrip != null ? (existingTrip['category'] ?? 'Factory Shift') : 'Factory Shift';
    TextEditingController routeController = TextEditingController(text: existingTrip?['route_details'] ?? '');
    TextEditingController incomeController = TextEditingController(text: existingTrip?['total_income']?.toString() ?? '');
    TextEditingController advanceController = TextEditingController(text: existingTrip?['advance']?.toString() ?? '');
    TextEditingController expenseController = TextEditingController(text: existingTrip?['expense']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingTrip == null ? "Add New Trip / Booking" : "Edit Trip Entry"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: ['Factory Shift', 'School Route', 'Contract Tour', 'Advance Booking', 'Local Trip']
                        .contains(selectedCategory) ? selectedCategory : 'Factory Shift',
                items: ['Factory Shift', 'School Route', 'Contract Tour', 'Advance Booking', 'Local Trip']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => selectedCategory = v!,
                decoration: const InputDecoration(labelText: "Sub-Category"),
              ),
              TextField(controller: routeController, decoration: const InputDecoration(labelText: "Route / Location Details")),
              TextField(controller: incomeController, decoration: const InputDecoration(labelText: "Total Income (PKR)"), keyboardType: TextInputType.number),
              TextField(controller: advanceController, decoration: const InputDecoration(labelText: "Advance Amount (PKR)"), keyboardType: TextInputType.number),
              TextField(controller: expenseController, decoration: const InputDecoration(labelText: "Expenses (PKR)"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'vehicle_no': widget.gariNo,
                'category': selectedCategory,
                'route_details': routeController.text,
                'total_income': double.tryParse(incomeController.text) ?? 0.0,
                'advance': double.tryParse(advanceController.text) ?? 0.0,
                'expense': double.tryParse(expenseController.text) ?? 0.0,
                'trip_date': DateTime.now().toString().substring(0, 10),
              };

              if (existingTrip == null) {
                await DBService.instance.insertTrip(data);
              } else {
                await DBService.instance.updateTrip(existingTrip['id'], data);
              }

              if (mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: const Text("Save Entry"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double netProfit = _totalIncome - _totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text("Gari ${widget.gariNo} - Pro Ledger"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final pdf = pw.Document();
              pdf.addPage(
                pw.Page(
                  build: (pw.Context context) => pw.Center(
                    child: pw.Text("Gari ${widget.gariNo} Statement - Total Profit: Rs. $netProfit"),
                  ),
                ),
              );
              await Printing.layoutPdf(onLayout: (format) async => pdf.save());
            },
          )
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Income: Rs. $_totalIncome", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text("Expense: Rs. $_totalExpense", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Text("NET PROFIT (SAFI BACHAT): Rs. $netProfit",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
              onPressed: () => _showTripDialog(),
              icon: const Icon(Icons.add),
              label: const Text("Add New Trip / Booking / Sub-category"),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text("${trip['category']} (${trip['route_details']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Date: ${trip['trip_date']}\nIncome: Rs. ${trip['total_income']} | Exp: Rs. ${trip['expense']}"),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: () => _openGoogleMap(trip['route_details']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showTripDialog(existingTrip: trip),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.green),
                          onPressed: () => _generatePDF(trip),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DBService.instance.deleteTrip(trip['id']);
                            _loadData();
                          },
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
    );
  }
}

