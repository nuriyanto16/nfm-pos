import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';

// ─── Providers ────────────────────────────────────────────────────────────────
final supplierListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ref.read(dioProvider).get('suppliers', queryParameters: {'limit': 100});
  if (res.data is Map && res.data.containsKey('rows')) {
    return res.data['rows'] as List<dynamic>;
  }
  return res.data as List<dynamic>;
});

final ingredientListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ref.read(dioProvider).get('ingredients', queryParameters: {'limit': 100});
  if (res.data is Map && res.data.containsKey('rows')) {
    return res.data['rows'] as List<dynamic>;
  }
  return res.data as List<dynamic>;
});

// ─── Supplier Management Screen ───────────────────────────────────────────────
class SupplierManagementScreen extends ConsumerStatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  ConsumerState<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends ConsumerState<SupplierManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Manajemen Supplier & Bahan Baku'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Supplier'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Bahan Baku'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SupplierTab(),
          _IngredientTab(),
        ],
      ),
    );
  }
}

// ─── Supplier Tab ─────────────────────────────────────────────────────────────
class _SupplierTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SupplierTab> createState() => _SupplierTabState();
}

class _SupplierTabState extends ConsumerState<_SupplierTab> {
  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Supplier'),
      ),
      body: suppliersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (suppliers) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: suppliers.length,
          itemBuilder: (context, i) {
            final s = suppliers[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: s['is_active'] == true ? colorScheme.primaryContainer : colorScheme.surfaceVariant,
                  child: Icon(Icons.local_shipping_outlined,
                    color: s['is_active'] == true ? colorScheme.primary : colorScheme.outline),
                ),
                title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s['contact_person'] != null) Text('PIC: ${s['contact_person']}', style: const TextStyle(fontSize: 12)),
                    Text('📞 ${s['phone'] ?? '-'}  ✉ ${s['email'] ?? '-'}', style: const TextStyle(fontSize: 11)),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showForm(context, s)),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                      onPressed: () => _delete(s['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Supplier'),
        content: const Text('Yakin hapus supplier ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(dioProvider).delete('suppliers/$id');
        ref.invalidate(supplierListProvider);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showForm(BuildContext context, Map<String, dynamic>? s) {
    final nameCtrl = TextEditingController(text: s?['name'] ?? '');
    final picCtrl = TextEditingController(text: s?['contact_person'] ?? '');
    final phoneCtrl = TextEditingController(text: s?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: s?['email'] ?? '');
    final addressCtrl = TextEditingController(text: s?['address'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s == null ? 'Tambah Supplier' : 'Edit Supplier'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Supplier *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: picCtrl, decoration: const InputDecoration(labelText: 'Contact Person', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telepon', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder()), maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                final dio = ref.read(dioProvider);
                final data = {
                  'name': nameCtrl.text, 'contact_person': picCtrl.text,
                  'phone': phoneCtrl.text, 'email': emailCtrl.text, 'address': addressCtrl.text,
                };
                if (s != null) { await dio.put('suppliers/${s['id']}', data: data); }
                else { await dio.post('suppliers', data: data); }
                ref.invalidate(supplierListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ─── Ingredient Tab ───────────────────────────────────────────────────────────
class _IngredientTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_IngredientTab> createState() => _IngredientTabState();
}

class _IngredientTabState extends ConsumerState<_IngredientTab> {
  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bahan'),
      ),
      body: ingredientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final stock = (item['stock'] as num).toDouble();
            final minStock = (item['min_stock'] as num).toDouble();
            final isLow = stock <= minStock;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLow ? Colors.red.withOpacity(0.15) : colorScheme.primaryContainer,
                  child: Icon(Icons.inventory_2_outlined, color: isLow ? Colors.red : colorScheme.primary),
                ),
                title: Row(
                  children: [
                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (isLow) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: const Text('Stok Rendah', style: TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: Colors.red,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  'Stok: ${stock} ${item['unit']} | Harga: ${formatRupiah((item['cost_per_unit'] as num).toDouble())}/${item['unit']}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showForm(context, item)),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Bahan'),
                            content: const Text('Yakin?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          try {
                            await ref.read(dioProvider).delete('ingredients/${item['id']}');
                            ref.invalidate(ingredientListProvider);
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showForm(BuildContext context, Map<String, dynamic>? item) {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final unitCtrl = TextEditingController(text: item?['unit'] ?? '');
    final stockCtrl = TextEditingController(text: (item?['stock'] ?? 0).toString());
    final costCtrl = TextEditingController(text: (item?['cost_per_unit'] ?? 0).toString());
    final minCtrl = TextEditingController(text: (item?['min_stock'] ?? 0).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Tambah Bahan Baku' : 'Edit Bahan Baku'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Bahan *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Satuan (gram, ml, pcs)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min. Stok', border: OutlineInputBorder()))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga/Satuan (Rp)', prefixText: 'Rp ', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || unitCtrl.text.isEmpty) return;
              try {
                final dio = ref.read(dioProvider);
                final data = {
                  'name': nameCtrl.text, 'unit': unitCtrl.text,
                  'stock': double.tryParse(stockCtrl.text) ?? 0,
                  'cost_per_unit': double.tryParse(costCtrl.text) ?? 0,
                  'min_stock': double.tryParse(minCtrl.text) ?? 0,
                };
                if (item != null) { await dio.put('ingredients/${item['id']}', data: data); }
                else { await dio.post('ingredients', data: data); }
                ref.invalidate(ingredientListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
