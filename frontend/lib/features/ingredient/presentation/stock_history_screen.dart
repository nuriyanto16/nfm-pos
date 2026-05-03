import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

final stockHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('stock/history');
  return response.data['rows'] as List<dynamic>;
});

class StockHistoryScreen extends ConsumerWidget {
  const StockHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(stockHistoryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Stok Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(stockHistoryProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (history) {
          if (history.isEmpty) {
            return const Center(child: Text('Belum ada riwayat pergerakan stok.'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return _buildDesktopTable(history, colorScheme);
              }
              return _buildMobileList(history, colorScheme);
            },
          );
        },
      ),
    );
  }

  Widget _buildDesktopTable(List<dynamic> history, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(colorScheme.primaryContainer.withOpacity(0.3)),
          columns: const [
            DataColumn(label: Text('Waktu')),
            DataColumn(label: Text('Cabang')),
            DataColumn(label: Text('Item')),
            DataColumn(label: Text('Tipe')),
            DataColumn(label: Text('Jumlah')),
            DataColumn(label: Text('Oleh')),
            DataColumn(label: Text('Keterangan')),
          ],
          rows: history.map((h) {
            final type = h['type']?.toString() ?? '-';
            final qty = h['quantity'] ?? 0.0;
            final color = _getTypeColor(type);

            return DataRow(cells: [
              DataCell(Text(DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(h['created_at'])))),
              DataCell(Text(h['branch']?['name'] ?? '-')),
              DataCell(Text(h['ingredient']?['name'] ?? '-')),
              DataCell(_buildTypeBadge(type, color)),
              DataCell(Text(
                '${qty > 0 ? "+" : ""}$qty',
                style: TextStyle(color: qty >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
              )),
              DataCell(Text(h['user']?['username'] ?? '-')),
              DataCell(Text(h['notes'] ?? '-')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<dynamic> history, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final h = history[index];
        final type = h['type']?.toString() ?? '-';
        final qty = h['quantity'] ?? 0.0;
        final color = _getTypeColor(type);
        final date = DateTime.parse(h['created_at']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTypeBadge(type, color),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(date),
                      style: TextStyle(fontSize: 12, color: colorScheme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h['ingredient']?['name'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cabang: ${h['branch']?['name'] ?? "-"}',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            'Oleh: ${h['user']?['username'] ?? "-"}',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${qty > 0 ? "+" : ""}$qty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: qty >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (h['notes'] != null && h['notes'] != '-') ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.notes, size: 14, color: colorScheme.outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          h['notes'],
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        type,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'IN': return Colors.green;
      case 'OUT': return Colors.red;
      case 'ADJUST': return Colors.blue;
      case 'WASTE': return Colors.orange;
      case 'VOID': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
