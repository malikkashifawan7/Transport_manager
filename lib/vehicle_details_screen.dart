import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'excel_export_service.dart';
import 'pdf_export_service.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final List<Map<String, dynamic>> records;

  const VehicleDetailsScreen({
    Key? key,
    required this.vehicle,
    required this.records,
  }) : super(key: key);

  @override
  _VehicleDetailsScreenState createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  // Auto Average Calculator (KM/L)
  double calculateAverage() {
    double totalKm = 0;
    double totalLitres = 0;

    for (var r in widget.records) {
      if (r['litres'] != null && (r['litres'] as num) > 0) {
        totalLitres += (r['litres'] as num).toDouble();
        totalKm += (r['meter_reading'] as num).toDouble();
      }
    }

    if (totalLitres == 0) return 0.0;
    return totalKm / totalLitres;
  }

  @override
  Widget build(BuildContext context) {
    double avg = calculateAverage();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle['number']} - Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () {
              PdfReportService.generateAndPrintVehicleLedger(
                  widget.vehicle, widget.records);
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export Excel',
            onPressed: () {
              ExcelExportService.exportLedgerToExcel(
                  widget.vehicle['number'], widget.records);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Bar Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Driver: ${widget.vehicle['driver_name'] ?? "N/A"}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Model: ${widget.vehicle['model'] ?? "N/A"}'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fuel Average:'),
                        Text(
                          '${avg.toStringAsFixed(2)} KM/L',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: avg > 3 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Google Map View Placeholder/Widget
            const Text('Vehicle Location Map',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(31.5204, 74.3587), // Lahore Default
                    zoom: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
