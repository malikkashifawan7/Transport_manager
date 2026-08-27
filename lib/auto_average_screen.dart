import 'package:flutter/material.dart';

class AutoAverageScreen extends StatefulWidget {
  const AutoAverageScreen({super.key});

  @override
  State<AutoAverageScreen> createState() => _AutoAverageScreenState();
}

class _AutoAverageScreenState extends State<AutoAverageScreen> {
  final _kmController = TextEditingController();
  final _litersController = TextEditingController();
  final _rateController = TextEditingController();

  double _average = 0.0;
  double _costPerKm = 0.0;

  void _calculate() {
    final km = double.tryParse(_kmController.text) ?? 0.0;
    final liters = double.tryParse(_litersController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;

    if (km > 0 && liters > 0) {
      setState(() {
        _average = km / liters;
        _costPerKm = (liters * rate) / km;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel & Auto Average Calculator'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _kmController,
              decoration: const InputDecoration(labelText: 'Total Kilometers Driven (KM)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _litersController,
              decoration: const InputDecoration(labelText: 'Total Diesel Consumed (Liters)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Diesel Rate Per Liter (Rs.)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: _calculate,
              child: const Text('Calculate Average'),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Vehicle Average: ${_average.toStringAsFixed(2)} KM/Liter', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                    const SizedBox(height: 8),
                    Text('Cost Per KM: Rs. ${_costPerKm.toStringAsFixed(2)} / KM', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
