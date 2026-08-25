import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExportService {
  static Future<void> exportAndShare(List<Map<String, dynamic>> records, String title) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    sheet.appendRow([
      'Date',
      'Type',
      'Category',
      'Title',
      'Amount (PKR)',
      'Litres',
      'Odometer (KM)',
    ]);

    for (var r in records) {
      sheet.appendRow([
        r['date']?.toString() ?? '',
        r['type']?.toString() ?? '',
        r['sub_category']?.toString() ?? '',
        r['title']?.toString() ?? '',
        double.tryParse(r['amount']?.toString() ?? '0') ?? 0.0,
        double.tryParse(r['litres']?.toString() ?? '0') ?? 0.0,
        double.tryParse(r['meter_reading']?.toString() ?? '0') ?? 0.0,
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/${title.replaceAll(' ', '_')}_Export.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles([XFile(filePath)], text: 'Exported Excel Report: $title');
    }
  }
}
