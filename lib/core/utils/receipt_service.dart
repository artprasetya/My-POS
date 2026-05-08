import 'package:intl/intl.dart';
import 'package:my_pos/features/transactions/domain/models/transaction.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptService {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static Future<void> generateAndPrint(Transaction transaction) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Standard receipt width
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('MY POS STORE',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Jl. Digital No. 123, Jakarta',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Telp: 0812-3456-7890',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 10),
                    pw.Text('RECEIPT',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                  ],
                ),
              ),

              // Transaction Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Order: ${transaction.transactionNumber}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                      DateFormat('dd/MM/yy HH:mm')
                          .format(transaction.createdAt),
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // Items
              pw.ListView.builder(
                itemCount: transaction.items.length,
                itemBuilder: (context, index) {
                  final item = transaction.items[index];
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                              '${item.productName} x${item.quantity}',
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            _currencyFormat
                                .format(item.unitPrice * item.quantity),
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              pw.Divider(thickness: 0.5),

              // Totals
              _buildTotalRow(
                  'Subtotal', _currencyFormat.format(transaction.subtotal)),
              if (transaction.discountAmount > 0)
                _buildTotalRow('Discount',
                    '-${_currencyFormat.format(transaction.discountAmount)}'),
              if (transaction.taxAmount > 0)
                _buildTotalRow(
                    'Tax', _currencyFormat.format(transaction.taxAmount)),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_currencyFormat.format(transaction.total),
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // Footer
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                        'Payment: ${transaction.paymentMethod.toUpperCase()}',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 10),
                    pw.Text('Thank you for shopping!',
                        style: pw.TextStyle(
                            fontSize: 10, fontStyle: pw.FontStyle.italic)),
                    pw.SizedBox(height: 5),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: transaction.transactionNumber,
                      width: 40,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Direct print or preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'receipt_${transaction.transactionNumber}.pdf',
    );
  }

  static pw.Widget _buildTotalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
