import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jurnal Umum')),
      body: FutureBuilder(
        future: ref.read(dioProvider).get('finance/journal'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data;
          final List entries = data is Map ? (data['rows'] ?? []) : (data ?? []);

          if (entries.isEmpty) {
            return const Center(child: Text('Tidak ada jurnal ditemukan'));
          }

          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final items = (entry['items'] as List?) ?? [];
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry['reference'] ?? 'Jurnal', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(entry['date']))),
                      ],
                    ),
                    Text(entry['description'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 8),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      children: [
                        const TableRow(children: [
                          Text('Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Debit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Kredit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ]),
                        ...items.map((item) {
                          final debit = (item['debit'] as num?)?.toDouble() ?? 0.0;
                          final credit = (item['credit'] as num?)?.toDouble() ?? 0.0;
                          return TableRow(children: [
                            Text(item['account'] != null ? item['account']['name'] : 'Unknown', style: const TextStyle(fontSize: 12)),
                            Text(debit > 0 ? NumberFormat.currency(locale: 'id_ID', symbol: '').format(debit) : '-', style: const TextStyle(fontSize: 12)),
                            Text(credit > 0 ? NumberFormat.currency(locale: 'id_ID', symbol: '').format(credit) : '-', style: const TextStyle(fontSize: 12)),
                          ]);
                        })
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
