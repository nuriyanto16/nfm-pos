import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final ingredientListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('ingredients');
  if (res.data is Map) return res.data['rows'] ?? [];
  return res.data ?? [];
});

class IngredientManagementScreen extends ConsumerStatefulWidget {
  const IngredientManagementScreen({super.key});

  @override
  ConsumerState<IngredientManagementScreen> createState() => _IngredientManagementScreenState();
}

class _IngredientManagementScreenState extends ConsumerState<IngredientManagementScreen> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Bahan Baku'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder(
        future: ref.read(dioProvider).get('ingredients'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final List ingredients = (snapshot.data?.data is Map) 
              ? snapshot.data?.data['rows'] ?? [] 
              : snapshot.data?.data ?? [];

          return ListView.builder(
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final ing = ingredients[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.science_outlined)),
                title: Text(ing['name']),
                subtitle: Text('Stok: ${ing['stock']} ${ing['unit']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rp ${ing['cost_per_unit']}/${ing['unit']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showIngredientDialog(context, ing)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteIngredient(ing['id'])),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIngredientDialog(context),
        label: const Text('Tambah Bahan'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showIngredientDialog(BuildContext context, [Map<String, dynamic>? item]) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final unitCtrl = TextEditingController(text: item?['unit'] ?? 'gram');
    final costCtrl = TextEditingController(text: item?['cost_per_unit']?.toString() ?? '0');
    final minCtrl = TextEditingController(text: item?['min_stock']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Tambah Bahan' : 'Edit Bahan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Bahan')),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Satuan (gram, ml, pcs, dll)')),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga per Satuan (Rp)')),
              TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok Minimal')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final data = {
                'name': nameCtrl.text,
                'unit': unitCtrl.text,
                'cost_per_unit': double.tryParse(costCtrl.text) ?? 0,
                'min_stock': double.tryParse(minCtrl.text) ?? 0,
              };
              final dio = ref.read(dioProvider);
              if (item == null) {
                await dio.post('ingredients', data: data);
              } else {
                await dio.put('ingredients/${item['id']}', data: data);
              }
              if (mounted) Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIngredient(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Bahan?'),
        content: const Text('Ini akan mempengaruhi resep yang menggunakan bahan ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(dioProvider).delete('ingredients/$id');
      _refresh();
    }
  }
}
