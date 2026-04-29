import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/pagination_controls.dart';
import 'ingredient_management_screen.dart';

final goodsReceiptProvider = StateNotifierProvider<GoodsReceiptNotifier, GoodsReceiptState>((ref) {
  return GoodsReceiptNotifier(ref);
});

final suppliersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('suppliers');
  final data = res.data;
  if (data is Map && data.containsKey('rows')) {
    return (data['rows'] as List<dynamic>?) ?? [];
  }
  return [];
});

final branchesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('branches');
  return (res.data as List<dynamic>?) ?? [];
});

class GoodsReceiptState {
  final List<dynamic> items;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final int totalRows;

  GoodsReceiptState({
    this.items = const [],
    this.isLoading = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRows = 0,
  });

  GoodsReceiptState copyWith({
    List<dynamic>? items,
    bool? isLoading,
    int? currentPage,
    int? totalPages,
    int? totalRows,
  }) {
    return GoodsReceiptState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRows: totalRows ?? this.totalRows,
    );
  }
}

class GoodsReceiptNotifier extends StateNotifier<GoodsReceiptState> {
  final Ref ref;
  GoodsReceiptNotifier(this.ref) : super(GoodsReceiptState()) {
    fetchReceipts();
  }

  Future<void> fetchReceipts({int page = 1}) async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('inventory/receipts', queryParameters: {'page': page, 'limit': 15});
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

  void setPage(int page) => fetchReceipts(page: page);
}

class GoodsReceiptScreen extends ConsumerWidget {
  const GoodsReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goodsReceiptProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Barang Masuk (Goods Receipt)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReceipt(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Catat Barang Masuk'),
      ),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              itemBuilder: (context, i) {
                final r = state.items[i];
                final isDraft = r['status'] == 'Draft';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDraft ? Colors.grey[200] : Colors.green[100],
                      child: Icon(Icons.input, color: isDraft ? Colors.grey : Colors.green),
                    ),
                    title: Row(
                      children: [
                        Text(r['receipt_no'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        _buildStatusBadge(r['status']),
                      ],
                    ),
                    subtitle: Text('${r['receipt_date'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(r['receipt_date'])) : '-'} · ${r['supplier']?['name'] ?? '-'}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatRupiah((r['total_amount'] as num?)?.toDouble() ?? 0.0), style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                        const Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                    onTap: () => _showReceiptDetail(context, ref, r['id']),
                  ),
                );
              },
            ),
          ),
          PaginationControls(
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            totalRows: state.totalRows,
            onPageChanged: (p) => ref.read(goodsReceiptProvider.notifier).setPage(p),
          ),
        ],
      ),
    );
  }

  void _showReceiptDetail(BuildContext context, WidgetRef ref, int id) async {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder(
        future: ref.read(dioProvider).get('inventory/receipts/$id'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final r = snapshot.data!.data;
          return AlertDialog(
            title: Text('Detail Barang Masuk: ${r['receipt_no']}'),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Supplier: ${r['supplier']?['name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('No. Invoice: ${r['vendor_invoice_no'] ?? '-'}'),
                            Text('Penerima (PIC): ${r['received_by'] ?? '-'}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Tanggal: ${r['receipt_date'] != null ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(r['receipt_date'])) : '-'}'),
                            Text('Cabang: ${r['branch']?['name'] ?? '-'}'),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text('Daftar Item:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text('Bahan', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('Harga', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                          ],
                        ),
                        ...(r['items'] as List).map((item) => TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text(item['ingredient']?['name'] ?? '-')),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${item['quantity']} ${item['ingredient']?['unit'] ?? ''}')),
                            Padding(padding: const EdgeInsets.all(8), child: Text(formatRupiah((item['cost_price'] as num?)?.toDouble() ?? 0.0))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(formatRupiah((item['subtotal'] as num?)?.toDouble() ?? 0.0))),
                          ],
                        )),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Keseluruhan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(formatRupiah((r['total_amount'] as num?)?.toDouble() ?? 0.0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue)),
                      ],
                    ),
                    if (r['notes'] != null && r['notes'].isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Catatan: ${r['notes']}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
              if (r['status'] == 'Draft')
                FilledButton.icon(
                  onPressed: () => _approveReceipt(context, ref, r['id']),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve & Update Stok'),
                ),
              FilledButton.icon(onPressed: () => _printReceipt(r), icon: const Icon(Icons.print), label: const Text('Cetak Bukti')),
            ],
          );
        },
      ),
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

  Future<void> _approveReceipt(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(dioProvider).put('inventory/receipts/$id/approve');
      ref.read(goodsReceiptProvider.notifier).fetchReceipts();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Barang Masuk disetujui & stok diperbarui!')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _printReceipt(Map<String, dynamic> receipt) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('BUKTI BARANG MASUK (GOODS RECEIPT)', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('No. Dokumen : ${receipt['receipt_no']}'),
                      pw.Text('No. Invoice   : ${receipt['vendor_invoice_no'] ?? '-'}'),
                      pw.Text('Supplier      : ${receipt['supplier']?['name'] ?? '-'}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Tanggal : ${receipt['receipt_date'] != null ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(receipt['receipt_date'])) : '-'}'),
                      pw.Text('Cabang  : ${receipt['branch']?['name'] ?? '-'}'),
                      pw.Text('Status  : ${receipt['status'] ?? 'Draft'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Bahan / Item', 'Qty', 'Satuan', 'Harga Satuan', 'Subtotal'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                data: (receipt['items'] as List).map((item) => [
                  item['ingredient']?['name'] ?? '-',
                  item['quantity'].toString(),
                  item['ingredient']?['unit'] ?? '',
                  formatRupiah((item['cost_price'] as num?)?.toDouble() ?? 0.0),
                  formatRupiah((item['subtotal'] as num?)?.toDouble() ?? 0.0),
                ]).toList(),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Keseluruhan: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(formatRupiah((receipt['total_amount'] as num?)?.toDouble() ?? 0.0), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),
              if (receipt['notes'] != null && receipt['notes'].toString().isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('Catatan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(receipt['notes']),
              ],
              pw.SizedBox(height: 50),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Diterima Oleh,'),
                      pw.SizedBox(height: 10),
                      pw.Text(receipt['received_by'] ?? '-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
      name: 'GR_${receipt['receipt_no']}',
    );
  }

  void _showAddReceipt(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddReceiptDialog(onSaved: () {
        ref.read(goodsReceiptProvider.notifier).fetchReceipts();
        Navigator.pop(ctx);
      }),
    );
  }
}

class _AddReceiptDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddReceiptDialog({required this.onSaved});

  @override
  ConsumerState<_AddReceiptDialog> createState() => _AddReceiptDialogState();
}

class _AddReceiptDialogState extends ConsumerState<_AddReceiptDialog> {
  int? _selectedSupplierId;
  int? _selectedBranchId;
  int? _selectedOrderId;
  final _invoiceCtrl = TextEditingController();
  final _picCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  bool _isSaving = false;
  List<dynamic> _approvedOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchApprovedOrders();
  }

  Future<void> _fetchApprovedOrders() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('inventory/branch-orders', queryParameters: {
        'status': 'Approved',
        'exclude_used': 'true',
        'limit': 100,
      });
      setState(() => _approvedOrders = res.data['rows'] ?? []);
    } catch (e) {
      debugPrint('Error fetching approved orders: $e');
    }
  }

  double _safeNum(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadOrderItems(int orderId) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('inventory/branch-orders/$orderId');
      final order = res.data;
      setState(() {
        _items.clear();
        for (var item in order['items'] ?? []) {
          final qty = _safeNum(item['approved_qty'] ?? item['quantity']);
          final cost = _safeNum(item['ingredient']?['cost_per_unit']);
          _items.add({
            'ingredient_id': item['ingredient_id'],
            'quantity': qty,
            'cost_price': cost,
            'subtotal': qty * cost,
            'unit': item['ingredient']?['unit'] ?? '',
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading order items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientListProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final branchesAsync = ref.watch(branchesProvider);

    return AlertDialog(
      title: const Text('Input Barang Masuk'),
      content: SizedBox(
        width: 800,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: suppliersAsync.when(
                      data: (list) => DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Supplier *', border: OutlineInputBorder()),
                        items: list.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name'] ?? '-'))).toList(),
                        onChanged: (v) => setState(() => _selectedSupplierId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error load suppliers'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: branchesAsync.when(
                      data: (list) => DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Cabang Penerima *', border: OutlineInputBorder()),
                        items: list.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(value: b['id'], child: Text(b['name'] ?? '-'))).toList(),
                        onChanged: (v) => setState(() {
                          _selectedBranchId = v;
                          _selectedOrderId = null;
                          _items.clear();
                          _fetchApprovedOrders(); // Re-fetch orders for the selected branch (or full list if admin)
                        }),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error load branches'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedOrderId,
                decoration: const InputDecoration(labelText: 'Sumber Order Cabang (Opsional - Jika ada)', border: OutlineInputBorder(), helperText: 'Pilih jika penerimaan ini berdasarkan request cabang yang disetujui'),
                items: _approvedOrders
                    .where((o) => _selectedBranchId == null || o['branch_id'] == _selectedBranchId)
                    .map<DropdownMenuItem<int>>((o) => DropdownMenuItem(value: o['id'], child: Text('${o['order_no']} (${o['branch'] != null ? o['branch']['name'] : '-'})')))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedOrderId = v);
                  if (v != null) _loadOrderItems(v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _invoiceCtrl, decoration: const InputDecoration(labelText: 'No. Invoice Supplier', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _picCtrl, decoration: const InputDecoration(labelText: 'Nama Penerima (PIC) *', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Catatan', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.list_alt, size: 20),
                  SizedBox(width: 8),
                  Text('Daftar Bahan Baku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Divider(),
              ..._items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: ingredientsAsync.when(
                          data: (list) => DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Pilih Bahan', border: OutlineInputBorder(), isDense: true),
                            value: item['ingredient_id'],
                            items: list.map<DropdownMenuItem<int>>((ing) => DropdownMenuItem(value: ing['id'], child: Text('${ing['name'] ?? '-'} (${ing['unit'] ?? '-'})'))).toList(),
                            onChanged: (v) {
                              setState(() {
                                item['ingredient_id'] = v;
                                final ing = (list as List).firstWhere((ing) => ing['id'] == v, orElse: () => null);
                                if (ing != null) {
                                  item['unit'] = ing['unit'];
                                  item['cost_price'] = _safeNum(ing['cost_per_unit']);
                                  item['subtotal'] = _safeNum(item['cost_price']) * _safeNum(item['quantity']);
                                }
                              });
                            },
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Error'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: item['quantity'].toString(),
                          decoration: InputDecoration(labelText: 'Qty ${item['unit'] != null ? '(${item['unit']})' : ''}', border: const OutlineInputBorder(), isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            setState(() {
                              item['quantity'] = double.tryParse(v) ?? 0.0;
                              item['subtotal'] = _safeNum(item['cost_price']) * _safeNum(item['quantity']);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: item['cost_price'].toString(),
                          decoration: const InputDecoration(labelText: 'Harga Beli', border: OutlineInputBorder(), isDense: true, prefixText: 'Rp '),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            setState(() {
                              item['cost_price'] = double.tryParse(v) ?? 0.0;
                              item['subtotal'] = _safeNum(item['cost_price']) * _safeNum(item['quantity']);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(formatRupiah(_safeNum(item['subtotal'])), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _items.removeAt(i))),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _items.add({'ingredient_id': null, 'quantity': 1.0, 'cost_price': 0.0, 'subtotal': 0.0})),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Bahan Lainnya'),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Transaksi:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(formatRupiah(_calculateTotal()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan & Update Stok'),
        ),
      ],
    );
  }

  double _calculateTotal() {
    try {
      double total = 0;
      for (var it in _items) { 
        total += _safeNum(it['subtotal']); 
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _save() async {
    if (_selectedBranchId == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi data dan item barang!')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('inventory/receipts', data: {
        'supplier_id': _selectedSupplierId,
        'branch_id': _selectedBranchId,
        'branch_order_id': _selectedOrderId,
        'vendor_invoice_no': _invoiceCtrl.text,
        'received_by': _picCtrl.text,
        'notes': _notesCtrl.text,
        'total_amount': _calculateTotal(),
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
