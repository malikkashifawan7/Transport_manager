import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExportService {
  static Future<void> exportLedgerToExcel(
      String vehicleNumber, List<Map<String, dynamic>> records) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Ledger Report'];
    excel.setDefaultSheet('Ledger Report');

    // Headers (Wrapped in TextCellValue)
    sheetObject.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Title'),
      TextCellValue('Amount (PKR)'),
      TextCellValue('Litres'),
      TextCellValue('Odometer (KM)')
    ]);

    // Data Rows
    for (var r in records) {
      sheetObject.appendRow([
        TextCellValue(r['date']?.toString() ?? ''),
        TextCellValue(r['type']?.toString() ?? ''),
        TextCellValue(r['sub_category']?.toString() ?? ''),
        TextCellValue(r['title']?.toString() ?? ''),
        IntCellValue(int.tryParse(r['amount']?.toString() ?? '0') ?? 0),
        IntCellValue(int.tryParse(r['litres']?.toString() ?? '0') ?? 0),
        IntCellValue(int.tryParse(r['meter_reading']?.toString() ?? '0') ?? 0),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/${vehicleNumber}_Ledger.xlsx";
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);

    // Share File
    await Share.shareXFiles([XFile(path)], text: 'Vehicle $vehicleNumber Ledger Report');
  }
}

