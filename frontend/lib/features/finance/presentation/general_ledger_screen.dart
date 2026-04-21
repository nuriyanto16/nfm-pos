import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

class GeneralLedgerScreen extends ConsumerStatefulWidget {
  const GeneralLedgerScreen({super.key});

  @override
  ConsumerState<GeneralLedgerScreen> createState() => _GeneralLedgerScreenState();
}

class _GeneralLedgerScreenState extends ConsumerState<GeneralLedgerScreen> {
  int? selectedAccountId;
  List<dynamic> accounts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get('finance/coa');
    setState(() => accounts = res.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buku Besar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<int>(
              value: selectedAccountId,
              hint: const Text('Pilih Akun'),
              items: accounts.map((a) => DropdownMenuItem<int>(
                value: a['id'],
                child: Text('${a['code']} - ${a['name']}'),
              )).toList(),
              onChanged: (v) => setState(() => selectedAccountId = v),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          if (selectedAccountId != null)
            Expanded(
              child: FutureBuilder(
                future: ref.read(dioProvider).get('finance/ledger', queryParameters: {'account_id': selectedAccountId}),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List data = snapshot.data?.data ?? [];

                  if (data.isEmpty) {
                    return const Center(child: Text('Tidak ada transaksi untuk akun ini.'));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Tanggal')),
                          DataColumn(label: Text('Keterangan')),
                          DataColumn(label: Text('Ref')),
                          DataColumn(label: Text('Debit')),
                          DataColumn(label: Text('Kredit')),
                          DataColumn(label: Text('Saldo')),
                        ],
                        rows: data.map((item) {
                          final debit = (item['debit'] as num?)?.toDouble() ?? 0.0;
                          final credit = (item['credit'] as num?)?.toDouble() ?? 0.0;
                          final balance = (item['balance'] as num?)?.toDouble() ?? 0.0;
                          return DataRow(cells: [
                            DataCell(Text(DateFormat('dd/MM/yy').format(DateTime.parse(item['date'])))),
                            DataCell(Text(item['description'] ?? '-')),
                            DataCell(Text(item['reference'] ?? '-')),
                            DataCell(Text(debit > 0 ? formatRupiah(debit) : '-')),
                            DataCell(Text(credit > 0 ? formatRupiah(credit) : '-')),
                            DataCell(Text(formatRupiah(balance), style: const TextStyle(fontWeight: FontWeight.bold))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            const Expanded(child: Center(child: Text('Silakan pilih akun untuk melihat buku besar.'))),
        ],
      ),
    );
  }

  String formatRupiah(dynamic value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(value);
  }
}
