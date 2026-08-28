import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfHelper {
  // Vehicle Wise Combined Statement & Invoice Print
  static Future<void> generateVehicleInvoice({
    required String vehicleNumber,
    required List<Map<String, dynamic>> fuelLogs,
    required List<Map<String, dynamic>> maintenanceLogs,
  }) async {
    final pdf = pw.Document();

    double totalFuelExpense = fuelLogs.fold(0, (sum, item) => sum + ((item['total_cost'] as num?)?.toDouble() ?? 0.0));
    double totalMaintenanceExpense = maintenanceLogs.fold(0, (sum, item) => sum + ((item['cost'] as num?)?.toDouble() ?? 0.0));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('Awan Brothers Tours & Travels', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                ),
                pw.Center(child: pw.Text('Vehicle Merged Ledger & Invoice Statement', style: const pw.TextStyle(fontSize: 14))),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 10),
                pw.Text('Vehicle Number: $vehicleNumber', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 15),

                pw.Text('Fuel Filling Logs:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Rate/L', 'Liters', 'Total Cost'],
                  data: fuelLogs.map((item) => [
                    item['date'] ?? '',
                    'Rs. ${item['rate']}',
                    '${item['liters']} L',
                    'Rs. ${item['total_cost']}'
                  ]).toList(),
                ),
                pw.SizedBox(height: 15),

                pw.Text('Maintenance Logs:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Work Done', 'Mechanic', 'Cost'],
                  data: maintenanceLogs.map((item) => [
                    item['date'] ?? '',
                    item['work_description'] ?? '',
                    item['mechanic_name'] ?? '',
                    'Rs. ${item['cost']}'
                  ]).toList(),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Fuel Expense:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs. ${totalFuelExpense.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Maintenance Expense:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs. ${totalMaintenanceExpense.toStringAsFixed(2)}'),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Grand Total Expense:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs. ${(totalFuelExpense + totalMaintenanceExpense).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Booking Invoice PDF Print/Export
  static Future<void> generateBookingPdf({
    required String customerName,
    required String phone,
    required String destination,
    required String date,
    required double amount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Awan Brothers Tours & Travels',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(child: pw.Text('Booking Receipt / Invoice', style: const pw.TextStyle(fontSize: 14))),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 20),
                _buildInfoRow('Customer Name:', customerName),
                _buildInfoRow('Phone Number:', phone),
                _buildInfoRow('Destination:', destination),
                _buildInfoRow('Date:', date),
                pw.SizedBox(height: 15),
                pw.Divider(),
                _buildInfoRow('Total Amount:', 'Rs. ${amount.toStringAsFixed(2)}', isBold: true),
                pw.Spacer(),
                pw.Center(child: pw.Text('Thank you for choosing Awan Brothers!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700))),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 14, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
