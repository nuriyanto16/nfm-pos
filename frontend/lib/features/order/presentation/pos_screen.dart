import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:go_router/go_router.dart';
import 'providers/cart_provider.dart';
import '../../customer/presentation/customer_provider.dart';
import '../../../core/utils/currency_formatter.dart';

final menuProvider = FutureProvider((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('menus', queryParameters: {'available': 'true', 'limit': 100});
  // Handle both standard list and paginated response
  if (response.data is Map && response.data.containsKey('rows')) {
    return response.data['rows'] as List<dynamic>;
  }
  return response.data as List<dynamic>;
});

final tableProvider = FutureProvider((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('tables', queryParameters: {'limit': 100});
  if (response.data is Map && response.data.containsKey('rows')) {
    return response.data['rows'] as List<dynamic>;
  }
  return response.data as List<dynamic>;
});

final activePromoProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('promos/active');
  if (response.data is Map && response.data.containsKey('rows')) {
    return response.data['rows'] as List<dynamic>;
  }
  return response.data as List<dynamic>;
});

final selectedCategoryProvider = StateProvider<int?>((ref) => null);
final menuSearchQueryProvider = StateProvider<String>((ref) => "");

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('categories');
  return res.data['rows'] as List<dynamic>;
});

final systemSettingsProvider = FutureProvider<Map<String, String>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('settings');
  return Map<String, String>.from(res.data);
});

// Searchable customer provider
final customerSearchQueryProvider = StateProvider<String>((ref) => "");
final customerSearchResultsProvider = FutureProvider<List<dynamic>>((ref) async {
  final query = ref.watch(customerSearchQueryProvider);
  if (query.length < 2) return [];
  
  final dio = ref.read(dioProvider);
  final response = await dio.get('customers', queryParameters: {'search': query, 'limit': 10});
  return response.data['rows'] as List<dynamic>;
});

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Kasir'),
        automaticallyImplyLeading: false,
        actions: [
          if (cartState.items.isNotEmpty)
            Badge(
              label: Text('${cartState.items.length}'),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showMobileCart(context, ref),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _buildDesktop(context, ref, cartState);
          }
          return _buildMobile(context, ref, cartState);
        },
      ),
    );
  }

  Widget _buildDesktop(BuildContext context, WidgetRef ref, CartState cartState) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _MenuArea(ref: ref),
        ),
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
          ),
          child: _CartPanel(cartState: cartState, ref: ref),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref, CartState cartState) {
    return _MenuArea(ref: ref);
  }

  void _showMobileCart(BuildContext context, WidgetRef ref) {
    final cartState = ref.read(cartProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) => _CartPanel(cartState: ref.watch(cartProvider), ref: ref),
        ),
      ),
    );
  }
}

// ─── Menu Area ────────────────────────────────────────────────────────────────
class _MenuArea extends ConsumerWidget {
  final WidgetRef ref;
  const _MenuArea({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(menuSearchQueryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Search & Category Area
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (v) => ref.read(menuSearchQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: 'Cari menu...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        // Category filter chips
        categoriesAsync.when(
          loading: () => const SizedBox(height: 56, child: Center(child: LinearProgressIndicator())),
          error: (_, __) => const SizedBox(height: 8),
          data: (cats) => SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Semua'),
                    selected: selectedCat == null,
                    onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = null,
                  ),
                ),
                ...cats.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat['name']),
                    selected: selectedCat == cat['id'],
                    onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state =
                        selectedCat == cat['id'] ? null : cat['id'],
                  ),
                )),
              ],
            ),
          ),
        ),

        // Menu Grid
        Expanded(
          child: menuAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (menus) {
              final filtered = menus.where((m) {
                final matchCategory = selectedCat == null || m['category_id'] == selectedCat;
                final matchSearch = searchQuery.isEmpty || 
                    m['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
                return matchCategory && matchSearch;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('Tidak ada menu tersedia'));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final menu = filtered[index];
                  return _MenuCard(menu: menu, index: index, onTap: () {
                    ref.read(cartProvider.notifier).addItem(menu);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${menu['name']} ditambahkan'),
                      duration: const Duration(milliseconds: 800),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                    ));
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Menu Card ────────────────────────────────────────────────────────────────
class _MenuCard extends ConsumerWidget {
  final Map<String, dynamic> menu;
  final int index;
  final VoidCallback onTap;

  const _MenuCard({required this.menu, required this.onTap, required this.index});

  String _getDummyImage() {
    final colors = ['FF5733', '33FF57', '3357FF', 'F333FF', 'FF33A8', '33FFF5'];
    final c = colors[index % colors.length];
    final name = menu['name'].toString().replaceAll(' ', '+');
    return 'https://ui-avatars.com/api/?name=$name&background=$c&color=fff&size=200&font-size=0.33';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final imgBase = ref.watch(imageBaseUrlProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
                child: (menu['image_url'] != null && menu['image_url'].toString().isNotEmpty)
                    ? Image.network(
                        '$imgBase${menu['image_url']}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.network(
                          _getDummyImage(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.fastfood, size: 40, color: colorScheme.primary),
                        ),
                      )
                    : Image.network(
                        _getDummyImage(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.fastfood, size: 40, color: colorScheme.primary),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    menu['category']['name'] ?? '',
                    style: TextStyle(fontSize: 10, color: colorScheme.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah((menu['price'] as num).toDouble()),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cart Panel ───────────────────────────────────────────────────────────────
class _CartPanel extends ConsumerWidget {
  final CartState cartState;
  final WidgetRef ref;

  const _CartPanel({required this.cartState, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final tablesAsync = ref.watch(tableProvider);
    final customersAsync = ref.watch(customerProvider);
    final promosAsync = ref.watch(activePromoProvider);
    final settingsAsync = ref.watch(systemSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Load settings once
    settingsAsync.whenData((settings) {
      final tax = double.tryParse(settings['tax_pct'] ?? '10') ?? 10.0;
      final service = double.tryParse(settings['service_charge_pct'] ?? '0') ?? 0.0;
      // Delay to avoid build phase conflict
      Future.microtask(() {
        if (ref.read(cartProvider).taxPct != tax || ref.read(cartProvider).serviceChargePct != service) {
          ref.read(cartProvider.notifier).setSettings(tax, service);
        }
      });
    });

    return Column(
      children: [
        // Handle (for bottom sheet)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.outline.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_outlined),
              const SizedBox(width: 8),
              const Text('Keranjang Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (cartState.items.isNotEmpty)
                TextButton.icon(
                  onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Kosongkan', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
        ),

        // Table & Customer selectors
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              tablesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (tables) => DropdownButtonFormField<int>(
                  value: cartState.tableId,
                  decoration: const InputDecoration(
                    labelText: 'Meja (opsional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.table_restaurant_outlined, size: 20),
                  ),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Take Away')),
                    ...tables.where((t) => t['status'] == 'Kosong' || t['id'] == cartState.tableId)
                        .map<DropdownMenuItem<int>>((t) => DropdownMenuItem(
                          value: t['id'],
                          child: Text('Meja ${t['table_number']} (${t['status']})'),
                        )),
                  ],
                  onChanged: (v) => ref.read(cartProvider.notifier).setTable(v),
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              // Optimal Customer Autocomplete
              LayoutBuilder(
                builder: (context, boxConstraints) => Autocomplete<Map<String, dynamic>>(
                  displayStringForOption: (option) => option['name'],
                  optionsBuilder: (textEditingValue) async {
                    if (textEditingValue.text.length < 2) {
                      ref.read(customerSearchQueryProvider.notifier).state = "";
                      return [];
                    }
                    ref.read(customerSearchQueryProvider.notifier).state = textEditingValue.text;
                    // We wait for the future provider to update
                    final results = await ref.read(customerSearchResultsProvider.future);
                    return results.cast<Map<String, dynamic>>();
                  },
                  onSelected: (selection) {
                    ref.read(cartProvider.notifier).setCustomer(selection['id'], selection['name']);
                  },
                  fieldViewBuilder: (ctx, textController, focusNode, onFieldSubmitted) {
                    // Pre-fill if customer already selected
                    if (cartState.customerName != null && textController.text.isEmpty) {
                      textController.text = cartState.customerName!;
                    }
                    return TextField(
                      controller: textController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Cari Customer...',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        suffixIcon: textController.text.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                textController.clear();
                                ref.read(cartProvider.notifier).setCustomer(null, null);
                              },
                            )
                          : null,
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: SizedBox(
                          width: boxConstraints.maxWidth,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option['name']),
                                subtitle: Text(option['phone'] ?? ''),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Promo selector
              promosAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (promos) => promos.isEmpty
                    ? const SizedBox.shrink()
                    : DropdownButtonFormField<int>(
                        value: cartState.promoId,
                        decoration: const InputDecoration(
                          labelText: 'Promo (opsional)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: Icon(Icons.local_offer_outlined, size: 20),
                        ),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('Tanpa Promo')),
                          ...promos.map<DropdownMenuItem<int>>((p) {
                            final val = (p['value'] as num).toDouble();
                            final label = p['type'] == 'percentage'
                                ? '${val.toInt()}% off'
                                : '${formatRupiah(val)} off';
                            return DropdownMenuItem(value: p['id'], child: Text('${p['name']} - $label'));
                          }),
                        ],
                        onChanged: (v) {
                          if (v == null) {
                            ref.read(cartProvider.notifier).applyPromo(null, 0, DiscountType.percentage);
                          } else {
                            final promo = promos.firstWhere((p) => p['id'] == v);
                            final type = promo['type'] == 'percentage' ? DiscountType.percentage : DiscountType.flat;
                            ref.read(cartProvider.notifier).applyPromo(v, (promo['value'] as num).toDouble(), type);
                          }
                        },
                      ),
              ),
              const SizedBox(height: 8),
              // Order Notes
              TextField(
                onChanged: (v) => ref.read(cartProvider.notifier).setNotes(v),
                decoration: const InputDecoration(
                  labelText: 'Catatan Pesanan (Global)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Cart items
        Expanded(
          child: cartState.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 56, color: colorScheme.outline),
                      const SizedBox(height: 8),
                      Text('Belum ada item', style: TextStyle(color: colorScheme.outline)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: cartState.items.length,
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatRupiah(item.price), style: TextStyle(color: colorScheme.primary, fontSize: 12)),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 32,
                              child: TextFormField(
                                initialValue: item.notes,
                                onChanged: (v) => ref.read(cartProvider.notifier).updateItemNote(item.menuId, v),
                                decoration: InputDecoration(
                                  hintText: 'Tambah catatan item...',
                                  hintStyle: const TextStyle(fontSize: 11),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.menuId, -1),
                              visualDensity: VisualDensity.compact,
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.menuId, 1),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () => ref.read(cartProvider.notifier).removeItem(item.menuId),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Summary & checkout
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'Subtotal', value: cartState.subtotal),
              if (cartState.discountAmount > 0)
                _SummaryRow(label: 'Diskon', value: -cartState.discountAmount, color: Colors.red),
              if (cartState.serviceChargePct > 0)
                _SummaryRow(label: 'Sesi Layanan (${cartState.serviceChargePct}%)', value: cartState.serviceChargeAmount),
              _SummaryRow(label: 'Pajak (${cartState.taxPct}%)', value: cartState.taxAmount),
              if (cartState.shippingFee > 0)
                _SummaryRow(label: 'Ongkir', value: cartState.shippingFee),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    formatRupiah(cartState.total),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: cartState.items.isEmpty ? null : () => _submitOrder(context, ref),
                      icon: const Icon(Icons.send),
                      label: const Text('Simpan & Kirim'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: cartState.items.isEmpty ? null : () => context.push('/payment'),
                      icon: const Icon(Icons.payment),
                      label: const Text('Bayar'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitOrder(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartProvider);
    try {
      final dio = ref.read(dioProvider);
      final orderData = {
        'table_id': cart.tableId,
        'customer_id': cart.customerId,
        'customer_name': cart.customerName ?? 'Pelanggan Umum',
        'discount_amount': cart.discountAmount,
        'notes': cart.notes ?? '',
        'items': cart.items.map((item) => {
          'menu_id': item.menuId,
          'quantity': item.quantity,
          'notes': item.notes,
        }).toList(),
      };
      
      await dio.post('orders', data: orderData);
      
      ref.read(cartProvider.notifier).clearCart();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pesanan dikirim ke dapur!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }
}

// ─── Summary Row ──────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;

  const _SummaryRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            formatRupiah(value),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
