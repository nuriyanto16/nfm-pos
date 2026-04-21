import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

class IngredientReportScreen extends ConsumerWidget {
  const IngredientReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Pemakaian Bahan')),
      body: FutureBuilder(
        future: ref.read(dioProvider).get('reports/ingredients'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final List data = snapshot.data?.data ?? [];

          if (data.isEmpty) {
            return const Center(child: Text('Belum ada data pemakaian bahan.'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Bahan')),
                DataColumn(label: Text('Jumlah Terpakai')),
                DataColumn(label: Text('Satuan')),
                DataColumn(label: Text('Estimasi Biaya')),
              ],
              rows: data.map((item) {
                return DataRow(cells: [
                  DataCell(Text(item['name'])),
                  DataCell(Text(item['total_qty'].toString())),
                  DataCell(Text(item['unit'])),
                  DataCell(Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(item['total_cost']))),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
