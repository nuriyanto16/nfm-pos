import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

class ReceiptView extends StatelessWidget {
  final Map<String, dynamic> order;
  final double amountPaid;
  final String paymentMethod;

  const ReceiptView({
    super.key,
    required this.order,
    required this.amountPaid,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final discount = (order['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final tax = (order['tax_amount'] as num?)?.toDouble() ?? 0.0;
    final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final change = paymentMethod == 'Tunai' ? amountPaid - total : 0.0;

    return Container(
      width: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          const Text('⭐ RESTO MODERN POS ⭐',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
          const SizedBox(height: 4),
          const Text('Jl. Merdeka No. 123, Jakarta',
              style: TextStyle(fontSize: 11, color: Colors.black87)),
          const Text('Telp: (021) 555-0123',
              style: TextStyle(fontSize: 11, color: Colors.black87)),
          const Divider(height: 24, thickness: 1, color: Colors.black54),

          // Order info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('No. #${order['id']}',
                  style: const TextStyle(fontSize: 12, color: Colors.black)),
              Text(
                DateTime.now().toLocal().toString().substring(0, 16),
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meja: ${order['table'] != null && order['table']['id'] != null ? order['table']['table_number'] : "Take Away"}',
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
              Text(
                'Kasir: ${order['user'] != null ? (order['user']['full_name'] ?? order['user']['username'] ?? 'Admin') : 'Admin'}',
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            ],
          ),
          if (order['customer_name'] != null &&
              order['customer_name'].toString().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Pelanggan: ${order['customer_name']}',
                  style: const TextStyle(fontSize: 12, color: Colors.black)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sumber: ${order['order_source'] ?? 'Resto'}',
                  style: const TextStyle(fontSize: 11, color: Colors.black)),
              Text('Metode: ${order['delivery_method'] ?? 'Dine In'}',
                  style: const TextStyle(fontSize: 11, color: Colors.black)),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: Colors.black54),

          // Items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (order['items'] as List?)?.length ?? 0,
            itemBuilder: (context, index) {
              final items = order['items'] as List?;
              if (items == null || index >= items.length) return const SizedBox.shrink();
              final item = items[index];
              final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;
              final price = (item['price'] as num?)?.toDouble() ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['menu']['name'],
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['quantity']} x ${formatRupiah(price)}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        Text(formatRupiah(subtotal),
                            style: const TextStyle(fontSize: 13, color: Colors.black)),
                      ],
                    ),
                    if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                      Text('  * ${item['notes']}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 20, thickness: 1, color: Colors.black54),

          // Pricing
          _ReceiptRow(label: 'Subtotal', value: (order['items'] as List?)?.fold(0.0, (s, i) => s! + ((i['subtotal'] as num?)?.toDouble() ?? 0)) ?? 0.0),
          if (discount > 0) _ReceiptRow(label: 'Diskon', value: -discount, color: Colors.red.shade700),
          _ReceiptRow(label: 'Pajak (10%)', value: tax),
          const Divider(height: 12, color: Colors.black54),
          _ReceiptRow(label: 'TOTAL', value: total, isBold: true, fontSize: 16),

          const SizedBox(height: 12),
          _ReceiptRow(label: 'Metode Bayar', valueText: paymentMethod),
          if (paymentMethod == 'Tunai') ...[
            _ReceiptRow(label: 'Bayar', value: amountPaid),
            _ReceiptRow(
              label: 'Kembalian',
              value: change,
              isBold: true,
              color: Colors.green.shade700,
            ),
          ],

          const Divider(height: 24, thickness: 1, color: Colors.black54),
          const Text('★ Terima Kasih Atas Kunjungan Anda ★',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('Simpan struk ini sebagai bukti pembelian',
              style: TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final double? value;
  final String? valueText;
  final bool isBold;
  final Color? color;
  final double fontSize;

  const _ReceiptRow({
    required this.label,
    this.value,
    this.valueText,
    this.isBold = false,
    this.color,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black)),
          Text(
            valueText ?? (value != null ? formatRupiah(value!) : '-'),
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black),
          ),
        ],
      ),
    );
  }
}
