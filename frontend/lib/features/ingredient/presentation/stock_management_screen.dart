import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

class StockManagementScreen extends ConsumerStatefulWidget {
  const StockManagementScreen({super.key});

  @override
  ConsumerState<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends ConsumerState<StockManagementScreen> {
  int? selectedIngredientId;
  List<dynamic> ingredients = [];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get('ingredients');
    setState(() {
      ingredients = (res.data is Map) ? res.data['rows'] ?? [] : res.data ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen & Historis Stok')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<int>(
              value: selectedIngredientId,
              hint: const Text('Pilih Bahan untuk Detail Penggunaan'),
              items: ingredients.map((i) => DropdownMenuItem<int>(
                value: i['id'],
                child: Text('${i['name']} (Stok: ${i['stock']} ${i['unit']})'),
              )).toList(),
              onChanged: (v) => setState(() => selectedIngredientId = v),
              decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
            ),
          ),
          Expanded(
            child: selectedIngredientId == null
                ? _buildOverallSummary()
                : _buildUsageHistory(selectedIngredientId!),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallSummary() {
    return ListView.builder(
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ing = ingredients[index];
        final isLow = (ing['stock'] as num) <= (ing['min_stock'] as num);
        
        return ListTile(
          leading: Icon(Icons.inventory_2, color: isLow ? Colors.red : Colors.blue),
          title: Text(ing['name']),
          subtitle: Text('Batas Minimal: ${ing['min_stock']} ${ing['unit']}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${ing['stock']} ${ing['unit']}', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLow ? Colors.red : null)),
              if (isLow) const Text('STOK RENDAH', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          onTap: () => setState(() => selectedIngredientId = ing['id']),
        );
      },
    );
  }

  Widget _buildUsageHistory(int ingredientId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Riwayat Penggunaan / Mutasi', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Tutup Detail'),
                onPressed: () => setState(() => selectedIngredientId = null),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: ref.read(dioProvider).get('ingredients/stock/history', queryParameters: {'ingredient_id': ingredientId}),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final List history = snapshot.data?.data ?? [];

              if (history.isEmpty) {
                return const Center(child: Text('Belum ada riwayat mutasi untuk bahan ini.'));
              }

              return ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final isOut = item['type'] == 'OUT' || item['type'] == 'WASTE';
                  
                  return ListTile(
                    leading: Icon(
                      isOut ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isOut ? Colors.red : Colors.green,
                    ),
                    title: Text(item['notes'] ?? 'Mutasi Stok'),
                    subtitle: Text(DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(item['created_at']))),
                    trailing: Text(
                      '${isOut ? "-" : "+"}${item['quantity']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOut ? Colors.red : Colors.green,
                        fontSize: 15,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
