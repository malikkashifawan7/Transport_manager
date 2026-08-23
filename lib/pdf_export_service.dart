import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfExportService {
  // Professional Standard Invoice & Thermal Print
  static Future<void> generateAndShareInvoice({
    required String gariNo,
    required String driverName,
    required String tourType, // Factory, School, Contract, Local
    required double totalAmount,
    required double advance,
    required double expense,
    required String date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              cross: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("TRANSPORT HISAB - TRIP INVOICE",
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text("Vehicle No: $gariNo", style: const pw.TextStyle(fontSize: 16)),
                pw.Text("Driver: $driverName"),
                pw.Text("Category / Route: $tourType"),
                pw.Text("Date: $date"),
                pw.SizedBox(height: 15),
                pw.TableHelper.fromTextArray(
                  headers: ['Description', 'Amount (PKR)'],
                  data: [
                    ['Total Booking Amount', totalAmount.toStringAsFixed(2)],
                    ['Advance Amount Paid', advance.toStringAsFixed(2)],
                    ['Fuel / Trip Expense', expense.toStringAsFixed(2)],
                    ['Net Profit / Bachat', (totalAmount - expense).toStringAsFixed(2)],
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text("Generated via Transport Hisab App",
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ],
            ),
          );
        },
      ),
    );

    // Save File Locally
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Invoice_$gariNo.pdf");
    await file.writeAsBytes(await pdf.save());

    // Share via WhatsApp or Direct Print
    await Share.shareXFiles([XFile(file.path)], text: 'Invoice for Gari $gariNo ($tourType)');
  }

  // Direct Thermal Printer Output
  static Future<void> printDirect(pw.Document pdf) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
