import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/receipt_printer.dart';

final orderDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('orders/$id');
  return res.data as Map<String, dynamic>;
});

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Proses':
        return Colors.blue;
      case 'Selesai':
        return Colors.green;
      case 'Batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_top;
      case 'Proses':
        return Icons.restaurant;
      case 'Selesai':
        return Icons.check_circle;
      case 'Batal':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pesanan #$orderId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Gagal memuat data: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (order) {
          final status = order['status'] as String;
          final statusCol = _statusColor(status);
          final items = order['items'] as List? ?? [];
          final table = order['table'];
          final customer = order['customer'];
          final user = order['user'];
          final createdAt = order['created_at']?.toString() ?? '';
          final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
          final taxAmount = (order['tax_amount'] as num?)?.toDouble() ?? 0;
          final serviceAmount = (order['service_charge_amount'] as num?)?.toDouble() ?? 0;
          final discountAmount = (order['discount_amount'] as num?)?.toDouble() ?? 0;
          final subtotal = totalAmount - taxAmount - serviceAmount + discountAmount;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 800;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildItemList(items, colorScheme),
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildStatusCard(status, statusCol, createdAt, colorScheme),
                            const SizedBox(height: 16),
                            _buildInfoCard(order, table, customer, user, colorScheme),
                            const SizedBox(height: 16),
                            _buildSummaryCard(subtotal, discountAmount, taxAmount, serviceAmount, totalAmount, colorScheme),
                            const SizedBox(height: 16),
                            _buildActionButtons(context, ref, order, status, statusCol),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusCard(status, statusCol, createdAt, colorScheme),
                    const SizedBox(height: 16),
                    _buildInfoCard(order, table, customer, user, colorScheme),
                    const SizedBox(height: 16),
                    _buildItemList(items, colorScheme),
                    const SizedBox(height: 16),
                    _buildSummaryCard(subtotal, discountAmount, taxAmount, serviceAmount, totalAmount, colorScheme),
                    const SizedBox(height: 16),
                    _buildActionButtons(context, ref, order, status, statusCol),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String status, Color statusCol, String createdAt, ColorScheme cs) {
    String formattedDate = '';
    try {
      formattedDate = createdAt.replaceAll('T', ' ').substring(0, 19);
    } catch (_) {
      formattedDate = createdAt;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusCol.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_statusIcon(status), color: statusCol, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pesanan #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(formattedDate, style: TextStyle(color: cs.outline, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusCol.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusCol),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusCol,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> order, dynamic table, dynamic customer, dynamic user, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informasi Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 24),
            _infoRow(Icons.table_restaurant, 'Meja',
                table != null && table['id'] != null ? 'Meja ${table['table_number']}' : 'Take Away'),
            _infoRow(Icons.person, 'Pelanggan',
                customer != null ? customer['name'] : (order['customer_name'] ?? 'Pelanggan Umum')),
            _infoRow(Icons.badge, 'Kasir',
                user != null ? (user['full_name'] ?? user['username'] ?? '-') : '-'),
            if (order['notes'] != null && order['notes'].toString().isNotEmpty)
              _infoRow(Icons.note_alt, 'Catatan', order['notes']),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(List items, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Daftar Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} item',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...items.map((item) {
              final menuName = item['menu']?['name'] ?? 'Menu';
              final qty = item['quantity'] ?? 0;
              final price = (item['price'] as num?)?.toDouble() ?? 0;
              final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;
              final itemNote = item['notes'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${qty}x',
                              style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(menuName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('@ ${formatRupiah(price)}', style: TextStyle(fontSize: 12, color: cs.outline)),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(subtotal),
                          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
                        ),
                      ],
                    ),
                    if (itemNote != null && itemNote.toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 48, top: 4),
                        child: Text(
                          '📝 $itemNote',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double subtotal, double discount, double tax, double service, double total, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 24),
            _priceRow('Subtotal', subtotal),
            if (service > 0) _priceRow('Biaya Layanan', service),
            if (discount > 0) _priceRow('Diskon', -discount, color: Colors.red),
            if (tax > 0) _priceRow('Pajak', tax),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Text(
                  formatRupiah(total),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: cs.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(formatRupiah(value), style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Map<String, dynamic> order, String status, Color statusCol) {
    final isPaid = order['is_paid'] == true || order['is_paid'] == 1;
    final canBePaid = !isPaid && (status == 'Pending' || status == 'Proses' || status == 'Siap');

    return Column(
      children: [
        if (canBePaid)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/payment?orderId=$orderId'),
              icon: const Icon(Icons.payment),
              label: const Text('Bayar Sekarang'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        if (!isPaid && (status == 'Pending' || status == 'Proses' || status == 'Siap')) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _voidOrder(context, ref),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text('Void / Batalkan Pesanan', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
        if (status == 'Selesai')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ReceiptPrinter.printReceipt(order),
              icon: const Icon(Icons.print),
              label: const Text('Cetak Struk'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
      ],
    );
  }

  Future<void> _voidOrder(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yakin ingin membatalkan (void) pesanan ini? Stok bahan akan dikembalikan.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan Pembatalan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Void'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (reasonController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan harus diisi!')));
        return;
      }

      try {
        final dio = ref.read(dioProvider);
        await dio.post('orders/$orderId/void', data: {'reason': reasonController.text});
        ref.invalidate(orderDetailProvider(orderId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Order berhasil di-void!'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Void: $e')));
        }
      }
    }
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Yakin ingin mengubah status ke "$status"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = ref.read(dioProvider);
        await dio.put('orders/$orderId/status', data: {'status': status});
        ref.invalidate(orderDetailProvider(orderId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status diubah ke $status'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }
}
