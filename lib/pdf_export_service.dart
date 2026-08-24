import 'package:pdf/pdf.dart';
import 'package:pdf/widgets' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  static Future<void> generateAndPrintVehicleLedger(
      Map<String, dynamic> vehicle, List<Map<String, dynamic>> records) async {
    final pdf = pw.Document();

    double totalIncome = 0;
    double totalExpense = 0;

    for (var r in records) {
      double amt = (r['amount'] as num).toDouble();
      if (r['type'] == 'Income') {
        totalIncome += amt;
      } else {
        totalExpense += amt;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Vehicle Report: ${vehicle['number']}',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Driver: ${vehicle['driver_name']} | Phone: ${vehicle['driver_phone']}'),
              pw.Text('Type: ${vehicle['type']} | Model: ${vehicle['model']}'),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Type', 'Category', 'Title', 'Amount (PKR)'],
                data: records.map((r) => [
                  r['date'] ?? '',
                  r['type'] ?? '',
                  r['sub_category'] ?? '',
                  r['title'] ?? '',
                  r['amount'].toString(),
                ]).toList(),
              ),
              pw.SizedBox(height: 15),
              pw.Divider(),
              pw.Text('Total Income: Rs. ${totalIncome.toStringAsFixed(0)}'),
              pw.Text('Total Expense: Rs. ${totalExpense.toStringAsFixed(0)}'),
              pw.Text('Net Balance: Rs. ${(totalIncome - totalExpense).toStringAsFixed(0)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
