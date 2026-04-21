import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:go_router/go_router.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final promoListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('promos', queryParameters: {'limit': 100});
  if (response.data is Map && response.data.containsKey('rows')) {
    return response.data['rows'] as List<dynamic>;
  }
  return response.data as List<dynamic>;
});

final activePromoProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('promos/active');
  if (response.data is Map && response.data.containsKey('rows')) {
    return response.data['rows'] as List<dynamic>;
  }
  return response.data as List<dynamic>;
});

// ─── Promo Management Screen ─────────────────────────────────────────────────

class PromoManagementScreen extends ConsumerStatefulWidget {
  const PromoManagementScreen({super.key});

  @override
  ConsumerState<PromoManagementScreen> createState() => _PromoManagementScreenState();
}

class _PromoManagementScreenState extends ConsumerState<PromoManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(promoListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Promo'),
        leading: context.canPop() ? const BackButton() : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromoForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Promo'),
      ),
      body: promosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (promos) {
          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Belum ada promo', style: TextStyle(color: colorScheme.outline)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              final isActive = promo['is_active'] == true;
              final type = promo['type'] == 'percentage' ? '%' : 'Rp';
              final value = (promo['value'] as num).toDouble();
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green.withOpacity(0.15) : colorScheme.surfaceVariant,
                    child: Text(
                      type == '%' ? '${value.toInt()}%' : 'Rp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isActive ? Colors.green : colorScheme.outline,
                      ),
                    ),
                  ),
                  title: Text(promo['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (promo['description'] != null && promo['description'].toString().isNotEmpty)
                        Text(promo['description'], style: const TextStyle(fontSize: 12)),
                      Text(
                        'Nilai: ${type == '%' ? '${value.toInt()}%' : formatRupiah(value)} | Min. order: ${formatRupiah((promo['min_order'] as num).toDouble())}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        onChanged: (_) => _togglePromo(promo['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showPromoForm(context, promo),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: colorScheme.error),
                        onPressed: () => _deletePromo(promo['id']),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _togglePromo(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('promos/$id/toggle');
      ref.invalidate(promoListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deletePromo(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Promo'),
        content: const Text('Yakin ingin menghapus promo ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final dio = ref.read(dioProvider);
        await dio.delete('promos/$id');
        ref.invalidate(promoListProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showPromoForm(BuildContext context, Map<String, dynamic>? promo) {
    showDialog(
      context: context,
      builder: (ctx) => _PromoFormDialog(
        promo: promo,
        onSaved: () {
          ref.invalidate(promoListProvider);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _PromoFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? promo;
  final VoidCallback onSaved;

  const _PromoFormDialog({this.promo, required this.onSaved});

  @override
  ConsumerState<_PromoFormDialog> createState() => _PromoFormDialogState();
}

class _PromoFormDialogState extends ConsumerState<_PromoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  String _type = 'percentage';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.promo != null) {
      final p = widget.promo!;
      _nameController.text = p['name'] ?? '';
      _descController.text = p['description'] ?? '';
      _type = p['type'] ?? 'percentage';
      _valueController.text = (p['value'] ?? 0).toString();
      _minOrderController.text = (p['min_order'] ?? 0).toString();
      _maxDiscountController.text = (p['max_discount'] ?? 0).toString();
      _isActive = p['is_active'] ?? true;
      if (p['start_date'] != null) _startDate = DateTime.parse(p['start_date']);
      if (p['end_date'] != null) _endDate = DateTime.parse(p['end_date']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.promo != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Promo' : 'Tambah Promo'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Promo *', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Tipe Diskon', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'percentage', child: Text('Persentase (%)')),
                    DropdownMenuItem(value: 'flat', child: Text('Nominal (Rp)')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _type == 'percentage' ? 'Nilai (%)  *' : 'Nilai (Rp) *',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minimum Order (Rp)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxDiscountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Maks. Diskon (0 = tanpa batas)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Mulai', style: TextStyle(fontSize: 13)),
                        subtitle: Text('${_startDate.toLocal().toString().substring(0, 10)}'),
                        trailing: const Icon(Icons.calendar_today, size: 18),
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (d != null) setState(() => _startDate = d);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Selesai', style: TextStyle(fontSize: 13)),
                        subtitle: Text('${_endDate.toLocal().toString().substring(0, 10)}'),
                        trailing: const Icon(Icons.calendar_today, size: 18),
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (d != null) setState(() => _endDate = d);
                        },
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Promo Aktif'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      final data = {
        'name': _nameController.text,
        'description': _descController.text,
        'type': _type,
        'value': double.tryParse(_valueController.text) ?? 0,
        'min_order': double.tryParse(_minOrderController.text) ?? 0,
        'max_discount': double.tryParse(_maxDiscountController.text) ?? 0,
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
        'is_active': _isActive,
      };
      if (widget.promo != null) {
        await dio.put('promos/${widget.promo!['id']}', data: data);
      } else {
        await dio.post('promos', data: data);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
