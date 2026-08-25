import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExportService {
  static Future<void> exportAndShare(List<Map<String, dynamic>> records, String title) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Title'),
      TextCellValue('Amount (PKR)'),
      TextCellValue('Litres'),
      TextCellValue('Odometer (KM)'),
    ]);

    for (var r in records) {
      sheetObject.appendRow([
        TextCellValue(r['date']?.toString() ?? ''),
        TextCellValue(r['type']?.toString() ?? ''),
        TextCellValue(r['sub_category']?.toString() ?? ''),
        TextCellValue(r['title']?.toString() ?? ''),
        DoubleCellValue(double.tryParse(r['amount']?.toString() ?? '0') ?? 0.0),
        DoubleCellValue(double.tryParse(r['litres']?.toString() ?? '0') ?? 0.0),
        DoubleCellValue(double.tryParse(r['meter_reading']?.toString() ?? '0') ?? 0.0),
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

