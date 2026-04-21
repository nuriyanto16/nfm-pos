import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/pagination_controls.dart';
import '../../branch/presentation/branch_provider.dart';
import 'table_provider.dart';

class TableManagementScreen extends ConsumerWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tableManagementProvider);
    final notifier = ref.read(tableManagementProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Meja')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTableForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Meja'),
      ),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: state.items.isEmpty && !state.isLoading
              ? const Center(child: Text('Tidak ada meja ditemukan'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.items.length,
                  itemBuilder: (context, i) {
                    final t = state.items[i];
                    final isOccupied = t['status'] == 'Digunakan';
                    return Card(
                      color: isOccupied ? colorScheme.errorContainer : colorScheme.surfaceVariant,
                      child: InkWell(
                        onTap: () => _showTableForm(context, ref, t),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.table_restaurant, color: isOccupied ? colorScheme.error : colorScheme.primary),
                              const SizedBox(height: 8),
                              Text('Meja ${t['table_number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Kapasitas: ${t['capacity']}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(t['status'] ?? 'Kosong', 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOccupied ? colorScheme.error : Colors.green)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.qr_code),
                                tooltip: 'Tampilkan Stiker QR',
                                onPressed: () {
                                  _showTableQR(context, t['table_number']);
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
          PaginationControls(
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            totalRows: state.totalRows,
            onPageChanged: (page) => notifier.setPage(page),
          ),
        ],
      ),
    );
  }

  void _showTableForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? table) {
    showDialog(
      context: context,
      builder: (ctx) => _TableFormDialog(
        table: table,
        onSaved: () {
          ref.read(tableManagementProvider.notifier).fetchTables();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showTableQR(BuildContext context, String tableNumber) {
    final qrData = 'https://pos-resto.local/order?table=$tableNumber';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('QR Code - Meja $tableNumber', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pelanggan memindai stiker mejanya di sini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(qrData, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}

class _TableFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? table;
  final VoidCallback onSaved;
  const _TableFormDialog({this.table, required this.onSaved});

  @override
  ConsumerState<_TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends ConsumerState<_TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  int? _selectedBranchId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _numberCtrl.text = widget.table!['table_number'] ?? '';
      _capacityCtrl.text = widget.table!['capacity']?.toString() ?? '2';
      _selectedBranchId = widget.table!['branch_id'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchProvider);

    return AlertDialog(
      title: Text(widget.table == null ? 'Tambah Meja' : 'Edit Meja'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _numberCtrl,
              decoration: const InputDecoration(labelText: 'Nomor Meja *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kapasitas *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            branchesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (branches) => DropdownButtonFormField<int>(
                value: _selectedBranchId,
                decoration: const InputDecoration(labelText: 'Cabang *', border: OutlineInputBorder()),
                items: branches.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']))).toList(),
                onChanged: (v) => setState(() => _selectedBranchId = v),
                validator: (v) => v == null ? 'Pilih cabang' : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        if (widget.table != null)
           TextButton(
             onPressed: () => _delete(widget.table!['id']),
             child: const Text('Hapus', style: TextStyle(color: Colors.red)),
           ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _delete(int id) async {
    try {
      await ref.read(dioProvider).delete('tables/$id');
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      final data = {
        'table_number': _numberCtrl.text,
        'capacity': int.tryParse(_capacityCtrl.text) ?? 2,
        'branch_id': _selectedBranchId,
        'status': widget.table?['status'] ?? 'Kosong',
      };
      if (widget.table != null) {
        await dio.put('tables/${widget.table!['id']}', data: data);
      } else {
        await dio.post('tables', data: data);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
