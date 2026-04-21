import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'currency_formatter.dart';

class ReceiptPrinter {
  static Future<void> printReceipt(Map<String, dynamic> order, {double? amountPaid, String? paymentMethod}) async {
    final doc = pw.Document();

    final items = order['items'] as List? ?? [];
    final table = order['table'];
    final customer = order['customer'];
    final user = order['user'];
    
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final taxAmount = (order['tax_amount'] as num?)?.toDouble() ?? 0;
    final discountAmount = (order['discount_amount'] as num?)?.toDouble() ?? 0;
    final subtotal = totalAmount - taxAmount + discountAmount;
    final change = amountPaid != null ? amountPaid - totalAmount : 0;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text('POS Resto Modern', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Jl. Resto Masa Depan No. 123', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Telp: 0812-3456-7890', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),

              // Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Order: #${order['id']}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(order['created_at']?.toString().substring(0, 16).replaceAll('T', ' ') ?? '', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kasir: ${user?['username'] ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Meja: ${table != null ? table['table_number'] : 'TA'}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pelanggan: ${customer?['name'] ?? order['customer_name'] ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),

              // Items
              ...items.map((item) {
                final itemName = item['menu']?['name'] ?? 'Item';
                final qty = item['quantity'];
                final price = (item['price'] as num).toDouble();
                final itemTotal = (item['subtotal'] as num).toDouble();

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(itemName, style: const pw.TextStyle(fontSize: 11)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('$qty x ${formatRupiahCompact(price)}', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text(formatRupiahCompact(itemTotal), style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),

              // Financials
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(formatRupiahCompact(subtotal), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Diskon', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('-${formatRupiahCompact(discountAmount)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pajak (10%)', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(formatRupiahCompact(taxAmount), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatRupiahCompact(totalAmount), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              if (amountPaid != null) ...[
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Metode', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(paymentMethod ?? '-', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tunai / Dibayar', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(formatRupiahCompact(amountPaid), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                if (change >= 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Kembali', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(formatRupiahCompact(change), style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
              ],

              pw.SizedBox(height: 20),
              pw.Text('Terima Kasih', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Silakan datang kembali', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    // Call the print function. 
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Struk_Pesanan_${order["id"]}',
    );
  }
}
