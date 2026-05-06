import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

final stockHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('stock/history');
  return response.data['rows'] as List<dynamic>;
});

class StockHistoryScreen extends ConsumerStatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari item, cabang, atau keterangan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (history) {
                final filtered = history.where((h) {
                  final q = _searchQuery.toLowerCase();
                  final itemName = (h['ingredient']?['name'] ?? '').toString().toLowerCase();
                  final branchName = (h['branch']?['name'] ?? '').toString().toLowerCase();
                  final notes = (h['notes'] ?? '').toString().toLowerCase();
                  final user = (h['user']?['username'] ?? '').toString().toLowerCase();
                  return itemName.contains(q) ||
                      branchName.contains(q) ||
                      notes.contains(q) ||
                      user.contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Data tidak ditemukan.'));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return _buildDesktopTable(filtered, colorScheme);
                    }
                    return _buildMobileList(filtered, colorScheme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<dynamic> history, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: DataTable(
            horizontalMargin: 12,
            columnSpacing: 24,
            headingRowHeight: 48,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 60,
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
                DataCell(Text(
                  DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(h['created_at'])),
                  style: const TextStyle(fontSize: 12),
                )),
                DataCell(Text(h['branch']?['name'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(h['ingredient']?['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                DataCell(_buildTypeBadge(type, color)),
                DataCell(Text(
                  '${qty > 0 ? "+" : ""}$qty',
                  style: TextStyle(
                      color: qty >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                )),
                DataCell(Text(h['user']?['username'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(SizedBox(
                  width: 200,
                  child: Text(
                    h['notes'] ?? '-',
                    style: TextStyle(fontSize: 11, color: colorScheme.outline),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<dynamic> history, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final h = history[index];
        final type = h['type']?.toString() ?? '-';
        final qty = h['quantity'] ?? 0.0;
        final color = _getTypeColor(type);
        final date = DateTime.parse(h['created_at']);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTypeBadge(type, color),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(date),
                      style: TextStyle(fontSize: 11, color: colorScheme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h['ingredient']?['name'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${h['branch']?['name'] ?? "-"} · ${h['user']?['username'] ?? "-"}',
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${qty > 0 ? "+" : ""}$qty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: qty >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (h['notes'] != null && h['notes'] != '-') ...[
                  const SizedBox(height: 8),
                  Text(
                    h['notes'],
                    style: TextStyle(fontSize: 11, color: colorScheme.outline, fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        type,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9),
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
