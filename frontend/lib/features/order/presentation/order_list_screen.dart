import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/skeleton.dart';

// ─── Status filter ─────────────────────────────────────────────────────────────
final orderStatusFilter = StateProvider<String>((ref) => 'Semua');
final orderSearchQuery = StateProvider<String>((ref) => '');
final orderPageProvider = StateProvider<int>((ref) => 1);

final ordersPaginationProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final status = ref.watch(orderStatusFilter);
  final page = ref.watch(orderPageProvider);
  final query = ref.watch(orderSearchQuery);

  final params = <String, dynamic>{
    'page': page,
    'limit': 10,
    'search': query,
  };
  
  if (status != 'Semua') {
    params['status'] = status;
  }

  final response = await dio.get('orders', queryParameters: params);
  return response.data as Map<String, dynamic>;
});

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  static const _statusTabs = ['Semua', 'Pending', 'Proses', 'Siap', 'Selesai', 'Batal'];

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Proses':
        return Colors.blue;
      case 'Siap':
        return Colors.green;
      case 'Selesai':
        return Colors.teal;
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
      case 'Siap':
        return Icons.delivery_dining;
      case 'Selesai':
        return Icons.check_circle;
      case 'Batal':
        return Icons.cancel;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(orderStatusFilter);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(ordersPaginationProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (v) => ref.read(orderSearchQuery.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan ID atau nama pelanggan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
          ),

          // ─── Status Tabs ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _statusTabs.length,
                itemBuilder: (context, index) {
                  final tab = _statusTabs[index];
                  final isSelected = tab == selectedStatus;
                  final tabColor = tab == 'Semua' ? colorScheme.primary : _statusColor(tab);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tab),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(orderStatusFilter.notifier).state = tab;
                      },
                      selectedColor: tabColor.withOpacity(0.2),
                      checkmarkColor: tabColor,
                      labelStyle: TextStyle(
                        color: isSelected ? tabColor : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                      side: isSelected ? BorderSide(color: tabColor) : null,
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── Order List ──────────────────────────────────────
          Expanded(
            child: ref.watch(ordersPaginationProvider).when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: ListSkeleton(itemCount: 8),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) {
                final orders = (data['rows'] as List? ?? []);
                final total = data['total_rows'] ?? 0;
                final page = data['page'] ?? 1;
                final totalPages = data['total_pages'] ?? 1;
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final status = order['status'] ?? '';
                          // ... items rendering ...
                          final table = order['table'];
                          final tableLabel = table != null && table['id'] != null
                              ? 'Meja ${table['table_number']}'
                              : 'Take Away';
                          final statusCol = _statusColor(status);
                          final itemCount = (order['items'] as List?)?.length ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.push('/orders/${order['id']}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: statusCol.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_statusIcon(status), color: statusCol, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text('#${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: statusCol.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: statusCol.withOpacity(0.5)),
                                                ),
                                                child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusCol)),
                                              ),
                                              if (order['is_paid'] == true) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(order['customer_name'] ?? 'Pelanggan Umum', style: const TextStyle(fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.table_restaurant, size: 13, color: colorScheme.outline),
                                              const SizedBox(width: 4),
                                              Text(tableLabel, style: TextStyle(fontSize: 12, color: colorScheme.outline)),
                                              const SizedBox(width: 12),
                                              Icon(Icons.access_time, size: 13, color: colorScheme.outline),
                                              const SizedBox(width: 4),
                                              Text(_formatTime(order['created_at']), style: TextStyle(fontSize: 12, color: colorScheme.outline)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(formatRupiah((order['total_amount'] as num?)?.toDouble() ?? 0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                                        const SizedBox(height: 8),
                                        if (order['is_paid'] != true)
                                          _SmallActionButton(
                                            icon: Icons.payment,
                                            label: 'Bayar',
                                            color: Colors.green,
                                            onTap: () => context.push('/payment?orderId=${order['id']}'),
                                          )
                                        else
                                          const Text('LUNAS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Pagination Controls
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Page $page of $totalPages ($total orders)', style: const TextStyle(fontSize: 12)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: page > 1 ? () => ref.read(orderPageProvider.notifier).state-- : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: page < totalPages ? () => ref.read(orderPageProvider.notifier).state++ : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      return dateStr.substring(11, 16);
    } catch (_) {
      return '-';
    }
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
