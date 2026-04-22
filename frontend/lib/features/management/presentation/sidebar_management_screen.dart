import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final sidebarListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('management/sidebar');
  return response.data as List<dynamic>;
});

class SidebarManagementScreen extends ConsumerWidget {
  const SidebarManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync = ref.watch(sidebarListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Sidebar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenuForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Menu'),
      ),
      body: menusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (menus) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: menus.length,
          itemBuilder: (context, i) {
            final menu = menus[i];
            return _MenuTile(menu: menu);
          },
        ),
      ),
    );
  }

  void _showMenuForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? menu) {
    final titleCtrl = TextEditingController(text: menu?['title'] ?? '');
    final pathCtrl = TextEditingController(text: menu?['path'] ?? '');
    final iconCtrl = TextEditingController(text: menu?['icon'] ?? '');
    final sortCtrl = TextEditingController(text: (menu?['sort_order'] ?? 0).toString());
    bool isHeader = menu?['is_header'] ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(menu == null ? 'Tambah Menu Sidebar' : 'Edit Menu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Menu *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Jadikan Header Group'),
                  value: isHeader,
                  onChanged: (v) => setDialogState(() => isHeader = v),
                ),
                if (!isHeader) ...[
                  const SizedBox(height: 12),
                  TextField(controller: pathCtrl, decoration: const InputDecoration(labelText: 'Path (URL) *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: 'Icon Name (e.g. dashboard)', border: OutlineInputBorder())),
                ],
                const SizedBox(height: 12),
                TextField(controller: sortCtrl, decoration: const InputDecoration(labelText: 'Urutan (Sort Order)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                try {
                  final dio = ref.read(dioProvider);
                  final data = {
                    'title': titleCtrl.text,
                    'path': isHeader ? "" : pathCtrl.text,
                    'icon': isHeader ? "" : iconCtrl.text,
                    'is_header': isHeader,
                    'sort_order': int.tryParse(sortCtrl.text) ?? 0,
                  };
                  if (menu != null) {
                    await dio.put('management/sidebar/${menu['id']}', data: data);
                  } else {
                    await dio.post('management/sidebar', data: data);
                  }
                  ref.invalidate(sidebarListProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends ConsumerWidget {
  final Map<String, dynamic> menu;
  const _MenuTile({required this.menu});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = (menu['children'] as List? ?? []);
    final isHeader = menu['is_header'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(isHeader ? Icons.label_important : Icons.link),
        title: Text(menu['title'] ?? '', style: TextStyle(fontWeight: isHeader ? FontWeight.bold : null)),
        subtitle: Text(menu['path'] ?? (isHeader ? 'HEADER' : '-')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined), 
              onPressed: () => const SidebarManagementScreen()._showMenuForm(context, ref, menu)
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red), 
              onPressed: () async {
                final confirm = await showDialog<bool>(
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
                if (confirm == true) {
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.delete('management/sidebar/${menu['id']}');
                    ref.invalidate(sidebarListProvider);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            ),
          ],
        ),
        children: children.map((c) => ListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          leading: const Icon(Icons.subdirectory_arrow_right, size: 16),
          title: Text(c['title'] ?? ''),
          subtitle: Text(c['path'] ?? ''),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () {}),
        )).toList(),
      ),
    );
  }
}
