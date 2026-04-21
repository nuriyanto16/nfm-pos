import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modul Keuangan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chart of Accounts'),
            Tab(text: 'Jurnal Umum'),
            Tab(text: 'Buku Besar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CoaTab(),
          JournalTab(),
          LedgerTab(),
        ],
      ),
    );
  }
}

// ─── Chart of Accounts Tab ───────────────────────────────────────────────────

class CoaTab extends ConsumerWidget {
  const CoaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(dioProvider).get('finance/coa'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final List accounts = snapshot.data?.data ?? [];

        return ListView.builder(
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final acc = accounts[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getAccountColor(acc['type']),
                child: Text(acc['code'][0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text('${acc['code']} - ${acc['name']}'),
              subtitle: Text(acc['type']),
              trailing: const Icon(Icons.chevron_right),
            );
          },
        );
      },
    );
  }

  Color _getAccountColor(String type) {
    switch (type) {
      case 'Asset': return Colors.green;
      case 'Liability': return Colors.red;
      case 'Equity': return Colors.orange;
      case 'Revenue': return Colors.blue;
      case 'Expense': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

// ─── Journal Tab ─────────────────────────────────────────────────────────────

class JournalTab extends ConsumerWidget {
  const JournalTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(dioProvider).get('finance/journal'),
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final List entries = snapshot.data?.data ?? [];

        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final items = entry['items'] as List;
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
                      ...items.map((item) => TableRow(children: [
                        Text(item['account']['name'], style: const TextStyle(fontSize: 12)),
                        Text(item['debit'] > 0 ? NumberFormat.currency(locale: 'id_ID', symbol: '').format(item['debit']) : '-', style: const TextStyle(fontSize: 12)),
                        Text(item['credit'] > 0 ? NumberFormat.currency(locale: 'id_ID', symbol: '').format(item['credit']) : '-', style: const TextStyle(fontSize: 12)),
                      ])),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Ledger Tab (Placeholder for now) ──────────────────────────────────────────

class LedgerTab extends StatelessWidget {
  const LedgerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Simulasi Buku Besar Berdasarkan Akun akan ditampilkan di sini.'));
  }
}
