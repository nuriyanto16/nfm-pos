import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/pagination_controls.dart';
import 'ingredient_management_screen.dart';

final goodsIssueProvider = StateNotifierProvider<GoodsIssueNotifier, GoodsIssueState>((ref) {
  return GoodsIssueNotifier(ref);
});

final branchesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('branches');
  return res.data as List<dynamic>;
});

class GoodsIssueState {
  final List<dynamic> items;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final int totalRows;

  GoodsIssueState({
    this.items = const [],
    this.isLoading = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRows = 0,
  });

  GoodsIssueState copyWith({
    List<dynamic>? items,
    bool? isLoading,
    int? currentPage,
    int? totalPages,
    int? totalRows,
  }) {
    return GoodsIssueState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRows: totalRows ?? this.totalRows,
    );
  }
}

class GoodsIssueNotifier extends StateNotifier<GoodsIssueState> {
  final Ref ref;
  GoodsIssueNotifier(this.ref) : super(GoodsIssueState()) {
    fetchIssues();
  }

  Future<void> fetchIssues({int page = 1}) async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('inventory/issues', queryParameters: {'page': page, 'limit': 15});
      state = state.copyWith(
        items: res.data['rows'],
        currentPage: res.data['current_page'],
        totalPages: res.data['total_pages'],
        totalRows: res.data['total_rows'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setPage(int page) => fetchIssues(page: page);
}

class GoodsIssueScreen extends ConsumerWidget {
  const GoodsIssueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goodsIssueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Barang Keluar (Goods Issue)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIssue(context, ref),
        icon: const Icon(Icons.remove_circle_outline),
        label: const Text('Catat Barang Keluar'),
      ),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              itemBuilder: (context, i) {
                final issue = state.items[i];
                final isDraft = issue['status'] == 'Draft';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDraft ? Colors.grey[200] : Colors.orange,
                      child: Icon(Icons.output, color: isDraft ? Colors.grey : Colors.white),
                    ),
                    title: Row(
                      children: [
                        Text(issue['issue_no'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        _buildStatusBadge(issue['status']),
                      ],
                    ),
                    subtitle: Text('${DateFormat('dd MMM yyyy').format(DateTime.parse(issue['issue_date']))} · ${issue['issue_category'] ?? 'Umum'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showIssueDetail(context, ref, issue['id']),
                  ),
                );
              },
            ),
          ),
          PaginationControls(
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            totalRows: state.totalRows,
            onPageChanged: (p) => ref.read(goodsIssueProvider.notifier).setPage(p),
          ),
        ],
      ),
    );
  }

  void _showIssueDetail(BuildContext context, WidgetRef ref, int id) async {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder(
        future: ref.read(dioProvider).get('inventory/issues/$id'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final issue = snapshot.data!.data;
          return AlertDialog(
            title: Text('Detail Barang Keluar: ${issue['issue_no']}'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(issue['issue_date']))}'),
                  Text('Cabang: ${issue['branch']?['name'] ?? '-'}'),
                  Text('Kategori: ${issue['issue_category'] ?? 'Umum'}'),
                  Text('Penanggung Jawab (PIC): ${issue['issued_by'] ?? '-'}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const Text('Daftar Item:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text('Bahan', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('Ket', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                        ],
                      ),
                      ...(issue['items'] as List).map((item) => TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(item['ingredient']?['name'] ?? '-')),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${item['quantity']} ${item['ingredient']?['unit'] ?? ''}')),
                          Padding(padding: const EdgeInsets.all(8), child: Text(item['notes'] ?? '-', style: const TextStyle(fontSize: 12))),
                        ],
                      )),
                    ],
                  ),
                  if (issue['notes'] != null && issue['notes'].isNotEmpty) ...[
                    const Divider(),
                    Text('Catatan: ${issue['notes']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
              if (issue['status'] == 'Draft')
                FilledButton.icon(
                  onPressed: () => _approveIssue(context, ref, issue['id']),
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve & Kurangi Stok'),
                ),
              FilledButton.icon(onPressed: () => _printIssue(issue), icon: const Icon(Icons.print), label: const Text('Cetak Bukti')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _printIssue(Map<String, dynamic> issue) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('BUKTI BARANG KELUAR (GOODS ISSUE)', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('No. Dokumen : ${issue['issue_no']}'),
                      pw.Text('Kategori    : ${issue['issue_category'] ?? 'Umum'}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Tanggal : ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(issue['issue_date']))}'),
                      pw.Text('Cabang  : ${issue['branch']?['name'] ?? '-'}'),
                      pw.Text('Status  : ${issue['status'] ?? 'Draft'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Bahan / Item', 'Qty', 'Satuan', 'Keterangan'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                },
                data: (issue['items'] as List).map((item) => [
                  item['ingredient']?['name'] ?? '-',
                  item['quantity'].toString(),
                  item['ingredient']?['unit'] ?? '',
                  item['notes'] ?? '-',
                ]).toList(),
              ),
              if (issue['notes'] != null && issue['notes'].toString().isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('Catatan Umum:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(issue['notes']),
              ],
              pw.SizedBox(height: 50),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Dikeluarkan Oleh,'),
                      pw.SizedBox(height: 10),
                      pw.Text(issue['issued_by'] ?? '-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 30),
                      pw.Text('( ........................... )'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Disetujui Oleh,'),
                      pw.SizedBox(height: 50),
                      pw.Text('( ........................... )'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'GI_${issue['issue_no']}',
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color = Colors.grey;
    if (status == 'Approved') color = Colors.green;
    if (status == 'Cancelled') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(status ?? 'Draft', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _approveIssue(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(dioProvider).put('inventory/issues/$id/approve');
      ref.read(goodsIssueProvider.notifier).fetchIssues();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Barang Keluar disetujui & stok dikurangi!')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddIssue(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddIssueDialog(onSaved: () {
        ref.read(goodsIssueProvider.notifier).fetchIssues();
        Navigator.pop(ctx);
      }),
    );
  }
}

class _AddIssueDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddIssueDialog({required this.onSaved});

  @override
  ConsumerState<_AddIssueDialog> createState() => _AddIssueDialogState();
}

class _AddIssueDialogState extends ConsumerState<_AddIssueDialog> {
  int? _selectedBranchId;
  String? _selectedCategory = 'Waste';
  final _picCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  bool _isSaving = false;

  final List<String> _categories = ['Waste', 'Damaged', 'Expired', 'Transfer Out', 'Adjustment', 'Other'];

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientListProvider);
    final branchesAsync = ref.watch(branchesProvider);

    return AlertDialog(
      title: const Text('Input Barang Keluar'),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: branchesAsync.when(
                      data: (list) => DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Cabang Pengirim *', border: OutlineInputBorder()),
                        items: list.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']))).toList(),
                        onChanged: (v) => setState(() => _selectedBranchId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error load branches'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategori Keluar', border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: _picCtrl, decoration: const InputDecoration(labelText: 'Penanggung Jawab (PIC) *', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Catatan Umum', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.list, size: 20),
                  SizedBox(width: 8),
                  Text('Daftar Bahan yang Keluar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Divider(),
              ..._items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ingredientsAsync.when(
                          data: (list) => DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Pilih Bahan', border: OutlineInputBorder(), isDense: true),
                            value: item['ingredient_id'],
                            items: list.map<DropdownMenuItem<int>>((ing) => DropdownMenuItem(value: ing['id'], child: Text('${ing['name']} (${ing['unit'] ?? '-'})'))).toList(),
                            onChanged: (v) {
                              setState(() {
                                item['ingredient_id'] = v;
                                final ing = (list as List).firstWhere((ing) => ing['id'] == v);
                                item['unit'] = ing['unit'];
                              });
                            },
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Error'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: item['quantity'].toString(),
                          decoration: InputDecoration(labelText: 'Qty ${item['unit'] != null ? '(${item['unit']})' : ''}', border: const OutlineInputBorder(), isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => item['quantity'] = double.tryParse(v) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: item['notes'],
                          decoration: const InputDecoration(labelText: 'Ket. Item', border: OutlineInputBorder(), isDense: true),
                          onChanged: (v) => setState(() => item['notes'] = v),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _items.removeAt(i))),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _items.add({'ingredient_id': null, 'quantity': 1.0, 'notes': ''})),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Baris'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Simpan & Kurangi Stok'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedBranchId == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi data!')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('inventory/issues', data: {
        'branch_id': _selectedBranchId,
        'issue_category': _selectedCategory,
        'issued_by': _picCtrl.text,
        'notes': _notesCtrl.text,
        'items': _items,
      });
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
