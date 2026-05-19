import 'dart:io';
import 'package:intl/intl.dart';
import 'package:my_pos/features/transactions/domain/models/transaction.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class ExcelExportService {
  static Future<void> exportTransactions(List<Transaction> transactions) async {
    // Create a new Excel document.
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Sales Report';

    // Headers
    sheet.getRangeByIndex(1, 1).setText('Date');
    sheet.getRangeByIndex(1, 2).setText('Order No');
    sheet.getRangeByIndex(1, 3).setText('Payment');
    sheet.getRangeByIndex(1, 4).setText('Items');
    sheet.getRangeByIndex(1, 5).setText('Total');

    // Style headers
    final Range headerRange = sheet.getRangeByName('A1:E1');
    headerRange.cellStyle.bold = true;
    headerRange.cellStyle.backColor = '#E0E0E0';

    // Data
    for (int i = 0; i < transactions.length; i++) {
      final txn = transactions[i];
      final row = i + 2;

      sheet.getRangeByIndex(row, 1).setDateTime(txn.createdAt);
      sheet.getRangeByIndex(row, 2).setText(txn.transactionNumber);
      sheet.getRangeByIndex(row, 3).setText(txn.paymentMethod.toUpperCase());

      final itemsSummary =
          txn.items.map((e) => '${e.productName} (x${e.quantity})').join(', ');
      sheet.getRangeByIndex(row, 4).setText(itemsSummary);

      sheet.getRangeByIndex(row, 5).setNumber(txn.total);
      sheet.getRangeByIndex(row, 5).numberFormat = '#,##0';
    }

    // Auto-fit columns
    sheet.getRangeByName('A1:E${transactions.length + 1}').autoFit();

    // Save and launch
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final String fileName =
        'SalesReport_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    if (kIsWeb) {
      // Web download
      final content = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(content);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile/Desktop save
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(bytes);
      // In a real app, you'd use a file opener or share plugin here
    }
  }
}
