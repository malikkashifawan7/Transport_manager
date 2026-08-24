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

    // Headers
    sheetObject.appendRow([
      'Date',
      'Type',
      'Category',
      'Title',
      'Amount (PKR)',
      'Litres',
      'Odometer (KM)'
    ]);

    // Data Rows
    for (var r in records) {
      sheetObject.appendRow([
        r['date']?.toString() ?? '',
        r['type']?.toString() ?? '',
        r['sub_category']?.toString() ?? '',
        r['title']?.toString() ?? '',
        r['amount'] ?? 0,
        r['litres'] ?? 0,
        r['meter_reading'] ?? 0,
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
