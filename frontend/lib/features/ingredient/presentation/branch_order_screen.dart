import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/pagination_controls.dart';
import '../../branch/presentation/branch_provider.dart';
import 'ingredient_management_screen.dart';

final branchOrderProvider = StateNotifierProvider<BranchOrderNotifier, BranchOrderState>((ref) {
  return BranchOrderNotifier(ref);
});

class BranchOrderState {
  final List<dynamic> items;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final int totalRows;

  BranchOrderState({
    this.items = const [],
    this.isLoading = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRows = 0,
  });

  BranchOrderState copyWith({
    List<dynamic>? items,
    bool? isLoading,
    int? currentPage,
    int? totalPages,
    int? totalRows,
  }) {
    return BranchOrderState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRows: totalRows ?? this.totalRows,
    );
  }
}

class BranchOrderNotifier extends StateNotifier<BranchOrderState> {
  final Ref ref;
  BranchOrderNotifier(this.ref) : super(BranchOrderState()) {
    fetchOrders();
  }

  Future<void> fetchOrders({int page = 1}) async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('inventory/branch-orders', queryParameters: {'page': page, 'limit': 15});
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

  void setPage(int page) => fetchOrders(page: page);
}

class BranchOrderScreen extends ConsumerWidget {
  const BranchOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchOrderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Antar Cabang (Request Item)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrder(context, ref),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Buat Request Baru'),
      ),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              itemBuilder: (context, i) {
                final order = state.items[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(order['status']).withOpacity(0.2),
                      child: Icon(Icons.inventory_2, color: _getStatusColor(order['status'])),
                    ),
                    title: Text(order['order_no'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${DateFormat('dd MMM yyyy').format(DateTime.parse(order['order_date']))} · ${order['branch']?['name'] ?? '-'}'),
                    trailing: _buildStatusBadge(order['status']),
                    onTap: () => _showOrderDetail(context, ref, order['id']),
                  ),
                );
              },
            ),
          ),
          PaginationControls(
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            totalRows: state.totalRows,
            onPageChanged: (p) => ref.read(branchOrderProvider.notifier).setPage(p),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Approved': return Colors.blue;
      case 'Fulfilled': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String? status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(status ?? 'Pending', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showOrderDetail(BuildContext context, WidgetRef ref, int id) async {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder(
        future: ref.read(dioProvider).get('inventory/branch-orders/$id'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final order = snapshot.data!.data;
          final bool isPending = order['status'] == 'Pending';
          
          return AlertDialog(
            title: Text('Detail Request: ${order['order_no']}'),
            content: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cabang: ${order['branch']?['name'] ?? '-'}'),
                  Text('Status: ${order['status']}'),
                  const Divider(),
                  const Text('Item yang Diminta:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.grey[300]!),
                    children: [
                      const TableRow(children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('Bahan', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Minta', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Disetujui', style: TextStyle(fontWeight: FontWeight.bold))),
                      ]),
                      ...(order['items'] as List).map((item) => TableRow(children: [
                        Padding(padding: const EdgeInsets.all(8), child: Text(item['ingredient']?['name'] ?? '-')),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${item['quantity']}')),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${item['approved_qty'] ?? '-'}')),
                      ])),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
              if (isPending) ...[
                FilledButton(
                  onPressed: () => _approveOrder(context, ref, order),
                  style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Approve / Sesuaikan'),
                ),
              ]
            ],
          );
        },
      ),
    );
  }

  Future<void> _approveOrder(BuildContext context, WidgetRef ref, Map<String, dynamic> order) async {
    // Show a dialog to adjust quantities
    final List<TextEditingController> controllers = (order['items'] as List).map((item) => TextEditingController(text: item['quantity'].toString())).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve & Sesuaikan Jumlah'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tentukan berapa jumlah yang akan dikirim dari pusat.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ...List.generate(controllers.length, (i) {
              final item = order['items'][i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(child: Text(item['ingredient']?['name'] ?? '-')),
                    const SizedBox(width: 12),
                    SizedBox(width: 100, child: TextField(controller: controllers[i], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()))),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final List<Map<String, dynamic>> itemsToUpdate = [];
              for (int i = 0; i < controllers.length; i++) {
                itemsToUpdate.add({
                  'id': order['items'][i]['id'],
                  'approved_qty': double.tryParse(controllers[i].text) ?? 0,
                });
              }
              await ref.read(dioProvider).put('inventory/branch-orders/${order['id']}/status', data: {
                'status': 'Approved',
                'items': itemsToUpdate,
              });
              ref.read(branchOrderProvider.notifier).fetchOrders();
              if (context.mounted) {
                Navigator.pop(ctx); // Close adjust dialog
                Navigator.pop(context); // Close detail dialog
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Request berhasil disetujui!')));
              }
            },
            child: const Text('Simpan & Approve'),
          ),
        ],
      ),
    );
  }

  void _showAddOrder(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AddOrderDialog(onSaved: () {
        ref.read(branchOrderProvider.notifier).fetchOrders();
        Navigator.pop(ctx);
      }),
    );
  }
}

class _AddOrderDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddOrderDialog({required this.onSaved});

  @override
  ConsumerState<_AddOrderDialog> createState() => _AddOrderDialogState();
}

class _AddOrderDialogState extends ConsumerState<_AddOrderDialog> {
  final _notesCtrl = TextEditingController();
  final _requestedByCtrl = TextEditingController();
  int? _selectedBranchId;
  final List<Map<String, dynamic>> _items = [];
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientListProvider);

    return AlertDialog(
      title: const Text('Buat Request Item (Ke Pusat)'),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _requestedByCtrl, decoration: const InputDecoration(labelText: 'Nama Pemohon (PIC) *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              ref.watch(branchProvider).when(
                data: (list) => DropdownButtonFormField<int>(
                  value: _selectedBranchId,
                  decoration: const InputDecoration(labelText: 'Cabang Peminta *', border: OutlineInputBorder()),
                  items: list.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']))).toList(),
                  onChanged: (v) => setState(() => _selectedBranchId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading branches'),
              ),
              const SizedBox(height: 12),
              TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Catatan Ke Pusat', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.list),
                  SizedBox(width: 8),
                  Text('Daftar Item yang Diminta', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            items: list.map<DropdownMenuItem<int>>((ing) => DropdownMenuItem(value: ing['id'], child: Text(ing['name']))).toList(),
                            onChanged: (v) => setState(() => item['ingredient_id'] = v),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Error'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: item['quantity'].toString(),
                          decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => item['quantity'] = double.tryParse(v) ?? 1),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _items.removeAt(i))),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _items.add({'ingredient_id': null, 'quantity': 1.0})),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Item'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Kirim Request'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_items.isEmpty || _requestedByCtrl.text.isEmpty || _selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi data (PIC, Cabang, dan Item)!')));
      return;
    }
    
    // Check if all items have selected ingredients
    if (_items.any((item) => item['ingredient_id'] == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon pilih bahan untuk semua baris!')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('inventory/branch-orders', data: {
        'requested_by': _requestedByCtrl.text,
        'branch_id': _selectedBranchId,
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
