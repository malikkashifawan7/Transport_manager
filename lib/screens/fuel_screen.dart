import 'package:flutter/material.dart';
import '../models/fuel_log_model.dart';
import '../services/fuel_service.dart';
import '../dialogs/add_edit_fuel_dialog.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({Key? key}) : super(key: key);

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  final FuelService _fuelService = FuelService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fuel & Expenses Ledger"),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: FutureBuilder<List<FuelLog>>(
        future: _fuelService.getFuelByVehicle(1), // Main ledger view
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(
              child: Text("No fuel entries found. Tap '+' to add fuel record."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.local_gas_station, color: Colors.white),
                  ),
                  title: Text("${log.fuelType} - ${log.totalUnits} Liters/Kg"),
                  subtitle: Text("Rate: Rs. ${log.ratePerUnit} | Date: ${log.date}\nNote: ${log.notes ?? 'N/A'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Rs. ${log.totalCost}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.green)),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final res = await showDialog(
                            context: context,
                            builder: (_) => AddEditFuelDialog(fuelLog: log),
                          );
                          if (res == true) setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _fuelService.deleteFuelLog(log.id!);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final res = await showDialog(
            context: context,
            builder: (_) => const AddEditFuelDialog(),
          );
          if (res == true) setState(() {});
        },
      ),
    );
  }
}

