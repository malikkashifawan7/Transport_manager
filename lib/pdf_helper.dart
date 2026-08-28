import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfHelper {
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
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text('Booking Receipt / Invoice',
                      style: const pw.TextStyle(fontSize: 14)),
                ),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 20),
                _buildInfoRow('Customer Name:', customerName),
                _buildInfoRow('Phone Number:', phone),
                _buildInfoRow('Destination:', destination),
                _buildInfoRow('Date:', date),
                pw.SizedBox(height: 15),
                pw.Divider(),
                _buildInfoRow('Total Amount:', 'Rs. ${amount.toStringAsFixed(2)}',
                    isBold: true),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text('Thank you for choosing Awan Brothers!',
                      style: pw.TextStyle(
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

