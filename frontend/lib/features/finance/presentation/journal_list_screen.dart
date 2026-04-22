import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_formatter.dart';

import '../../../shared/widgets/skeleton.dart';

final journalPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final journalPaginationProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final page = ref.watch(journalPageProvider);
  final res = await dio.get('finance/journal', queryParameters: {'page': page, 'limit': 15});
  return res.data as Map<String, dynamic>;
});

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalPaginationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Umum'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(journalPaginationProvider),
          ),
        ],
      ),
      body: journalAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ListSkeleton(itemCount: 10),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final entries = (data['rows'] as List? ?? []);
          final total = data['total_rows'] ?? 0;
          final page = data['page'] ?? 1;
          final totalPages = data['total_pages'] ?? 1;

          if (entries.isEmpty) {
            return const Center(child: Text('Tidak ada jurnal ditemukan'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final items = (entry['items'] as List?) ?? [];
                    final date = DateTime.tryParse(entry['date'] ?? '') ?? DateTime.now();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry['reference'] ?? 'Jurnal', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(entry['description'] ?? '', 
                                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(DateFormat('dd MMM yyyy').format(date), 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(DateFormat('HH:mm').format(date), 
                                        style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2.5),
                                1: FlexColumnWidth(1),
                                2: FlexColumnWidth(1),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
                                  ),
                                  children: [
                                    const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('AKUN ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5))),
                                    Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('DEBIT', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5, color: colorScheme.primary))),
                                    Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('KREDIT', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5, color: colorScheme.error))),
                                  ],
                                ),
                                ...items.map((item) {
                                  final debit = (item['debit'] as num?)?.toDouble() ?? 0.0;
                                  final credit = (item['credit'] as num?)?.toDouble() ?? 0.0;
                                  final accountName = item['account'] != null ? item['account']['name'] : 'Unknown';
                                  final accountCode = item['account'] != null ? item['account']['code'] : '';
                                  
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(accountName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                            Text(accountCode, style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Text(debit > 0 ? formatRupiah(debit) : '-', 
                                            textAlign: TextAlign.right, 
                                            style: TextStyle(fontSize: 13, color: debit > 0 ? colorScheme.primary : null, fontWeight: debit > 0 ? FontWeight.bold : null)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Text(credit > 0 ? formatRupiah(credit) : '-', 
                                            textAlign: TextAlign.right, 
                                            style: TextStyle(fontSize: 13, color: credit > 0 ? colorScheme.error : null, fontWeight: credit > 0 ? FontWeight.bold : null)),
                                      ),
                                    ],
                                  );
                                })
                              ],
                            ),
                          ),
                        ],
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
                    Text('Page $page of $totalPages ($total entries)', style: const TextStyle(fontSize: 12)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: page > 1 ? () => ref.read(journalPageProvider.notifier).state-- : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: page < totalPages ? () => ref.read(journalPageProvider.notifier).state++ : null,
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
    );
  }
}
