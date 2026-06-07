import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:image_picker/image_picker.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/pagination_controls.dart';
import '../../../shared/widgets/skeleton.dart';
import 'menu_provider.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final categoryListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final posType = ref.watch(menuPosTypeProvider);
  final res = await dio.get('categories', queryParameters: {'limit': 100, 'pos_type': posType});
  if (res.data is Map) return res.data['rows'] as List<dynamic>;
  return res.data as List<dynamic>;
});

final branchListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('branches', queryParameters: {'active': 'true', 'limit': 100});
  if (res.data is Map && res.data.containsKey('rows')) {
    return res.data['rows'] as List<dynamic>;
  }
  return res.data as List<dynamic>;
});

final companyDropdownProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('companies');
  return res.data as List<dynamic>;
});

// ─── Dummy images ────────────────────────────────────────────────────────────
const _dummyFoodImages = [
  'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1499028344343-cd173ffc68a9?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=300&h=300&fit=crop',
];

const _dummyFashionImages = [
  'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=300&h=300&fit=crop',
];

const _dummyRetailImages = [
  'https://images.unsplash.com/photo-1542838132-92c53300491e?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=300&h=300&fit=crop',
];

const _dummyJasaImages = [
  'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1521566652839-697aa473761a?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=300&h=300&fit=crop',
  'https://images.unsplash.com/photo-1582733712530-09ac7c6c63cf?w=300&h=300&fit=crop',
];

String _getDummyImage(String posType, int index) {
  switch (posType) {
    case 'fashion':
      return _dummyFashionImages[index % _dummyFashionImages.length];
    case 'retail':
      return _dummyRetailImages[index % _dummyRetailImages.length];
    case 'jasa':
      return _dummyJasaImages[index % _dummyJasaImages.length];
    default:
      return _dummyFoodImages[index % _dummyFoodImages.length];
  }
}

// ─── Menu Management Screen ───────────────────────────────────────────────────
class MenuManagementScreen extends ConsumerStatefulWidget {
  final String initialType;
  const MenuManagementScreen({super.key, this.initialType = 'resto'});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuPosTypeProvider.notifier).state = widget.initialType;
      ref.read(menuManagementProvider.notifier).setPosType(widget.initialType);
      ref.read(categoryManagementProvider.notifier).fetchCategories(page: 1, posType: widget.initialType);
    });
  }

  @override
  void didUpdateWidget(covariant MenuManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(menuPosTypeProvider.notifier).state = widget.initialType;
          ref.read(menuManagementProvider.notifier).setPosType(widget.initialType);
          ref.read(categoryManagementProvider.notifier).fetchCategories(page: 1, posType: widget.initialType);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activePosType = ref.watch(menuPosTypeProvider);
    final isRestoMode = activePosType == 'resto';

    String getTitle() {
      switch (activePosType) {
        case 'fashion':
          return 'Manajemen Barang (Fashion)';
        case 'retail':
          return 'Manajemen Barang (Retail)';
        case 'jasa':
          return 'Manajemen Layanan Jasa';
        default:
          return 'Manajemen Menu Resto';
      }
    }

    String getTab1Label() {
      if (activePosType == 'jasa') return 'Daftar Layanan';
      if (activePosType == 'resto') return 'Daftar Item';
      return 'Daftar Barang';
    }

    String getTab2Label() {
      if (activePosType == 'jasa') return 'Kategori Layanan';
      if (activePosType == 'resto') return 'Kategori';
      return 'Kategori Barang';
    }

    IconData getTab1Icon() {
      switch (activePosType) {
        case 'fashion':
          return Icons.checkroom;
        case 'retail':
          return Icons.storefront;
        case 'jasa':
          return Icons.dry_cleaning;
        default:
          return Icons.restaurant_menu;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(getTitle()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(getTab1Icon()), text: getTab1Label()),
            Tab(icon: const Icon(Icons.category), text: getTab2Label()),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.initialType != 'resto')
            Container(
              color: colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _posTypeChip('fashion', 'Fashion', Icons.checkroom),
                    const SizedBox(width: 8),
                    _posTypeChip('retail', 'Retail / Toko', Icons.storefront),
                    const SizedBox(width: 8),
                    _posTypeChip('jasa', 'Jasa (Laundry/Salon)', Icons.dry_cleaning),
                  ],
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MenuTab(onRefresh: () => ref.read(menuManagementProvider.notifier).fetchMenus()),
                _CategoryTab(onRefresh: () => ref.read(categoryManagementProvider.notifier).fetchCategories()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _posTypeChip(String value, String label, IconData icon) {
    final activePosType = ref.watch(menuPosTypeProvider);
    final isSelected = activePosType == value;
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
      label: Text(label),
      selected: isSelected,
      selectedColor: colorScheme.primary,
      onSelected: (selected) {
        if (selected) {
          ref.read(menuPosTypeProvider.notifier).state = value;
          ref.read(menuManagementProvider.notifier).setPosType(value);
          ref.read(categoryManagementProvider.notifier).fetchCategories(page: 1, posType: value);
        }
      },
    );
  }
}

// ─── Menu Tab ─────────────────────────────────────────────────────────────────
class _MenuTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _MenuTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(menuManagementProvider);
    final notifier = ref.read(menuManagementProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final activePosType = ref.watch(menuPosTypeProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari menu...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => notifier.setSearch(v),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showMenuForm(context, ref, null),
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: state.isLoading
                    ? (activePosType == 'resto'
                        ? GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 320,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: 6,
                            itemBuilder: (context, i) => const CardSkeleton(),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: List.generate(
                                5,
                                (index) => const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Skeleton(width: 40, height: 40, borderRadius: 8),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Skeleton(width: 150, height: 16),
                                            SizedBox(height: 6),
                                            Skeleton(width: 100, height: 12),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ))
                    : state.items.isEmpty
                        ? const Center(child: Text('Tidak ada menu ditemukan'))
                        : activePosType == 'resto'
                      ? GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 320,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: state.items.length,
                          itemBuilder: (context, i) {
                            final m = state.items[i];
                            return _MenuCard(
                              menu: m,
                              index: i,
                              onEdit: () => _showMenuForm(context, ref, m),
                              onDelete: () => _deleteMenu(context, ref, m['id']),
                              onRecipe: () => _showRecipeDialog(context, m),
                            );
                          },
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              width: MediaQuery.of(context).size.width > 800
                                  ? MediaQuery.of(context).size.width - 272
                                  : 800,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                                decoration: BoxDecoration(
                                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                columns: const [
                                  DataColumn(label: Text('GAMBAR', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('NAMA ITEM', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('KATEGORI', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('HARGA', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('STOK', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: List.generate(state.items.length, (index) {
                                  final m = state.items[index];
                                  final isAvailable = m['is_available'] == true;
                                  final hasImage = m['image_url'] != null && m['image_url'].toString().isNotEmpty;
                                  final imgBase = ref.watch(imageBaseUrlProvider);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: hasImage
                                                ? Image.network(
                                                    '$imgBase${m['image_url']}',
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Image.network(
                                                      _getDummyImage(activePosType, index),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Image.network(
                                                    _getDummyImage(activePosType, index),
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(m['category']?['name'] ?? '-')),
                                      DataCell(Text(formatRupiah((m['price'] as num).toDouble()))),
                                      DataCell(Text('${m['stock'] ?? 0}')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isAvailable ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isAvailable ? 'AKTIF' : 'NONAKTIF',
                                            style: TextStyle(
                                              color: isAvailable ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 20),
                                              onPressed: () => _showMenuForm(context, ref, m),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                                              onPressed: () => _deleteMenu(context, ref, m['id']),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
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
        ),
      ],
    );
  }

  void _showRecipeDialog(BuildContext context, Map<String, dynamic> menu) {
    showDialog(context: context, builder: (ctx) => _RecipeDialog(menu: menu));
  }

  Future<void> _deleteMenu(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: const Text('Yakin ingin menghapus menu ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(dioProvider).delete('menus/$id');
        ref.read(menuManagementProvider.notifier).fetchMenus();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showMenuForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? menu) {
    showDialog(
      context: context,
      builder: (ctx) => _MenuFormDialog(
        menu: menu,
        onSaved: () {
          ref.read(menuManagementProvider.notifier).fetchMenus();
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─── Menu Card ────────────────────────────────────────────────────────────────
class _MenuCard extends ConsumerWidget {
  final Map<String, dynamic> menu;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRecipe;

  const _MenuCard({required this.menu, required this.index, required this.onEdit, required this.onDelete, required this.onRecipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAvailable = menu['is_available'] == true;
    final hasImage = menu['image_url'] != null && menu['image_url'].toString().isNotEmpty;
    final imgBase = ref.watch(imageBaseUrlProvider);
    final activePosType = ref.watch(menuPosTypeProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: colorScheme.surfaceContainerHighest,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image: use uploaded or dummy
                  hasImage
                      ? Image.network(
                          '$imgBase${menu['image_url']}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.network(
                            _getDummyImage(activePosType, index),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.fastfood, size: 48, color: colorScheme.outline),
                          ),
                        )
                      : Image.network(
                          _getDummyImage(activePosType, index),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.fastfood, size: 48, color: colorScheme.outline),
                        ),
                  if (!isAvailable)
                    Container(
                      color: Colors.black45,
                      child: const Center(child: Text('NONAKTIF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                    ),
                  // Recipe badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: onRecipe,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.science_outlined, size: 14, color: Colors.orangeAccent),
                            SizedBox(width: 4),
                            Text('Resep', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(menu['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(menu['category']?['name'] ?? '', style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatRupiah((menu['price'] as num).toDouble()), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: [
                        IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit),
                        const SizedBox(width: 8),
                        IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.error), onPressed: onDelete),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Tab ─────────────────────────────────────────────────────────────
class _CategoryTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _CategoryTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryManagementProvider);
    final notifier = ref.read(categoryManagementProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCatForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: state.items.isEmpty && !state.isLoading
              ? const Center(child: Text('Tidak ada kategori ditemukan'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, i) {
                    final cat = state.items[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.category_outlined)),
                        title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(cat['description'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showCatForm(context, ref, cat)),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: colorScheme.error),
                              onPressed: () => _deleteCat(context, ref, cat['id']),
                            ),
                          ],
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

  Future<void> _deleteCat(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text('Yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(dioProvider).delete('categories/$id');
        ref.read(categoryManagementProvider.notifier).fetchCategories();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCatForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? cat) {
    final nameCtrl = TextEditingController(text: cat?['name'] ?? '');
    final descCtrl = TextEditingController(text: cat?['description'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cat == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                final dio = ref.read(dioProvider);
                final data = {
                  'name': nameCtrl.text,
                  'description': descCtrl.text,
                  'pos_type': cat != null ? cat['pos_type'] : ref.read(menuPosTypeProvider),
                };
                if (cat != null) {
                  await dio.put('categories/${cat['id']}', data: data);
                } else {
                  await dio.post('categories', data: data);
                }
                ref.read(categoryManagementProvider.notifier).fetchCategories();
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Form Dialog (with Image Upload) ─────────────────────────────────────
class _MenuFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? menu;
  final VoidCallback onSaved;

  const _MenuFormDialog({this.menu, required this.onSaved});

  @override
  ConsumerState<_MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends ConsumerState<_MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedBranchId;
  int? _selectedCompanyId;
  bool _isAvailable = true;
  bool _isSaving = false;
  String? _imageUrl;
  bool _isUploading = false;
  String _selectedPosType = 'resto';

  @override
  void initState() {
    super.initState();
    _selectedPosType = ref.read(menuPosTypeProvider);
    if (widget.menu != null) {
      final m = widget.menu!;
      _nameController.text = m['name'] ?? '';
      _descController.text = m['description'] ?? '';
      _priceController.text = (m['price'] ?? 0).toString();
      _stockController.text = (m['stock'] ?? 0).toString();
      _selectedCategoryId = m['category_id'];
      _selectedBranchId = m['branch_id'];
      _selectedCompanyId = m['company_id'];
      _isAvailable = m['is_available'] ?? true;
      _imageUrl = m['image_url'];
      _selectedPosType = m['pos_type'] ?? 'resto';
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
      
      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final bytes = await pickedFile.readAsBytes();
      final formData = dio_pkg.FormData.fromMap({
        'image': dio_pkg.MultipartFile.fromBytes(bytes, filename: pickedFile.name),
      });

      final dio = ref.read(dioProvider);
      final response = await dio.post('menus/upload', data: formData);

      if (response.statusCode == 200) {
        setState(() {
          _imageUrl = response.data['url'];
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoryListProvider);
    final branchesAsync = ref.watch(branchListProvider);
    final isEdit = widget.menu != null;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Menu' : 'Tambah Menu'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image upload area
                InkWell(
                  onTap: _isUploading ? null : _pickAndUploadImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                    ),
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : _imageUrl != null && _imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      '${ref.watch(imageBaseUrlProvider)}$_imageUrl',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text('Ganti', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 40, color: colorScheme.outline),
                                  const SizedBox(height: 8),
                                  Text('Klik untuk upload gambar', style: TextStyle(color: colorScheme.outline, fontSize: 13)),
                                  Text('JPG, PNG (maks 2MB)', style: TextStyle(color: colorScheme.outline.withOpacity(0.6), fontSize: 11)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                ref.watch(companyDropdownProvider).when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error load company'),
                  data: (companies) {
                    final valueExists = _selectedCompanyId != null && companies.any((c) => c['id'] == _selectedCompanyId);
                    return DropdownButtonFormField<int>(
                      value: valueExists ? _selectedCompanyId : null,
                      decoration: const InputDecoration(labelText: 'Perusahaan *', border: OutlineInputBorder()),
                      items: companies.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
                      onChanged: (v) => setState(() => _selectedCompanyId = v),
                      validator: (v) => v == null ? 'Pilih perusahaan' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedPosType,
                  decoration: const InputDecoration(labelText: 'Tipe POS *', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'resto', child: Text('F&B (Resto/Cafe)')),
                    DropdownMenuItem(value: 'fashion', child: Text('POS Fashion')),
                    DropdownMenuItem(value: 'retail', child: Text('POS Retail/Toko')),
                    DropdownMenuItem(value: 'jasa', child: Text('POS Jasa (Laundry/Salon)')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedPosType = v;
                        _selectedCategoryId = null; // Reset category
                      });
                      ref.read(menuPosTypeProvider.notifier).state = v;
                    }
                  },
                ),
                const SizedBox(height: 12),
                catsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error load category'),
                  data: (cats) {
                    final valueExists = cats.any((c) => c['id'] == _selectedCategoryId);
                    return DropdownButtonFormField<int>(
                      value: valueExists ? _selectedCategoryId : null,
                      decoration: const InputDecoration(labelText: 'Kategori *', border: OutlineInputBorder()),
                      items: cats.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      validator: (v) => v == null ? 'Pilih kategori' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                branchesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (branches) {
                    final valueExists = _selectedBranchId == null || branches.any((b) => b['id'] == _selectedBranchId);
                    return DropdownButtonFormField<int>(
                      value: valueExists ? _selectedBranchId : null,
                      decoration: const InputDecoration(labelText: 'Cabang (Kosong = Global)', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text('Global (Semua Cabang)')),
                        ...branches.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']))),
                      ],
                      onChanged: (v) => setState(() => _selectedBranchId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Menu *', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Harga (Rp) *', border: OutlineInputBorder(), prefixText: 'Rp '),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Menu Tersedia'),
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
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
        'company_id': _selectedCompanyId,
        'category_id': _selectedCategoryId,
        'branch_id': _selectedBranchId,
        'name': _nameController.text,
        'description': _descController.text,
        'price': double.tryParse(_priceController.text) ?? 0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'is_available': _isAvailable,
        'image_url': _imageUrl,
        'pos_type': _selectedPosType,
      };
      if (widget.menu != null) {
        await dio.put('menus/${widget.menu!['id']}', data: data);
      } else {
        await dio.post('menus', data: data);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─── Recipe Management Provider ───────────────────────────────────────────────
final ingredientDropdownProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('ingredients', queryParameters: {'limit': 200});
  if (res.data is Map) return res.data['rows'] as List<dynamic>;
  return res.data as List<dynamic>;
});

// ─── Recipe Dialog (Fixed) ────────────────────────────────────────────────────
class _RecipeDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> menu;
  const _RecipeDialog({required this.menu});

  @override
  ConsumerState<_RecipeDialog> createState() => _RecipeDialogState();
}

class _RecipeDialogState extends ConsumerState<_RecipeDialog> {
  List<Map<String, dynamic>> _recipeItems = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchRecipe();
  }

  Future<void> _fetchRecipe() async {
    try {
      final res = await ref.read(dioProvider).get('menus/${widget.menu['id']}/ingredients');
      setState(() {
        _recipeItems = List<Map<String, dynamic>>.from(res.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addIngredient() {
    setState(() {
      _recipeItems.add({
        'menu_id': widget.menu['id'],
        'ingredient_id': null,
        'qty_used': 1.0,
        'unit': '',
        'ingredient': null,
      });
    });
  }

  Future<void> _saveRecipe() async {
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      final data = _recipeItems.map((item) => {
        'menu_id': widget.menu['id'],
        'ingredient_id': item['ingredient_id'],
        'qty_used': item['qty_used'] ?? 1.0,
        'unit': item['unit'] ?? '',
      }).toList();

      await dio.post('menus/${widget.menu['id']}/ingredients', data: data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Komposisi disimpan')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientDropdownProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.science_outlined, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text('Resep: ${widget.menu['name']}')),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 500,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info bar
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tentukan bahan baku yang digunakan untuk membuat "${widget.menu['name']}". Stok bahan akan otomatis berkurang saat ada pesanan.',
                          style: TextStyle(fontSize: 12, color: colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _recipeItems.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.science_outlined, size: 48, color: colorScheme.outline),
                            const SizedBox(height: 8),
                            const Text('Belum ada bahan baku terdaftar'),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _addIngredient,
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Bahan Pertama'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _recipeItems.length,
                        itemBuilder: (context, i) {
                          final item = _recipeItems[i];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  // Ingredient dropdown
                                  Expanded(
                                    flex: 3,
                                    child: ingredientsAsync.when(
                                      loading: () => const Text('Loading...'),
                                      error: (_, __) => const Text('Err'),
                                      data: (list) {
                                        final valueExists = list.any((ing) => ing['id'] == item['ingredient_id']);
                                        return DropdownButtonFormField<int>(
                                          value: valueExists ? item['ingredient_id'] : null,
                                          decoration: const InputDecoration(
                                            labelText: 'Bahan Baku',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          items: list.map((ing) => DropdownMenuItem(
                                            value: ing['id'] as int,
                                            child: Text('${ing['name']} (${ing['unit']})'),
                                          )).toList(),
                                        onChanged: (v) {
                                          setState(() {
                                            item['ingredient_id'] = v;
                                            // Auto-fill unit from selected ingredient
                                            if (v != null) {
                                              final selected = list.firstWhere((ing) => ing['id'] == v, orElse: () => {});
                                              item['unit'] = selected['unit'] ?? '';
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                                  const SizedBox(width: 10),
                                  // Qty field
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: (item['qty_used'] ?? 1.0).toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Jumlah',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (v) {
                                        item['qty_used'] = double.tryParse(v) ?? 1.0;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Unit label
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      item['unit'] ?? item['ingredient']?['unit'] ?? '',
                                      style: TextStyle(fontSize: 12, color: colorScheme.outline, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  // Delete
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => setState(() => _recipeItems.removeAt(i)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 8),
                if (_recipeItems.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Bahan'),
                  ),
              ],
            ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: _isSaving ? null : _saveRecipe,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan Komposisi'),
        ),
      ],
    );
  }
}
