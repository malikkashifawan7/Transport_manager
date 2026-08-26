import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfExportService {
  static Future<void> generateAndShareInvoice(
      String title, List<Map<String, dynamic>> records) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            cross: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Type', 'Category', 'Title', 'Amount'],
                data: records
                    .map((r) => [
                          r['type']?.toString() ?? '',
                          r['sub_category']?.toString() ?? '',
                          r['title']?.toString() ?? '',
                          r['amount']?.toString() ?? '0',
                        ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/${title.replaceAll(' ', '_')}_Report.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(filePath)], text: 'Exported Report: $title');
  }
}
