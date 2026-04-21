import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/pagination_controls.dart';
import 'customer_provider.dart';

class CustomerManagementScreen extends ConsumerStatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  ConsumerState<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends ConsumerState<CustomerManagementScreen> {
  String _search = '';

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Gold': return Colors.amber;
      case 'Silver': return Colors.blueGrey;
      default: return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerManagementProvider);
    final notifier = ref.read(customerManagementProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Customer')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama atau telepon...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => notifier.setSearch(v),
            ),
          ),
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: state.customers.isEmpty && !state.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('Tidak ada customer ditemukan', style: TextStyle(color: colorScheme.outline)),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return _buildTable(state.customers, colorScheme);
                      }
                      return _buildList(state.customers, colorScheme);
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

  Widget _buildTable(List customers, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      child: Card(
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(colorScheme.surfaceVariant),
          columns: const [
            DataColumn(label: Text('Nama')),
            DataColumn(label: Text('Telepon')),
            DataColumn(label: Text('Tier')),
            DataColumn(label: Text('Poin')),
            DataColumn(label: Text('Total Belanja')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: customers.map<DataRow>((c) {
            final tier = c['tier'] ?? 'Bronze';
            return DataRow(cells: [
              DataCell(Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(c['phone'] ?? '-')),
              DataCell(Chip(
                label: Text(tier, style: const TextStyle(fontSize: 11, color: Colors.white)),
                backgroundColor: _tierColor(tier),
                visualDensity: VisualDensity.compact,
              )),
              DataCell(Text('${c['loyalty_points'] ?? 0}')),
              DataCell(Text(formatRupiah((c['total_spent'] as num? ?? 0).toDouble()))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showForm(context, c)),
                  IconButton(icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error), onPressed: () => _delete(c['id'])),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList(List customers, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: customers.length,
      itemBuilder: (context, i) {
        final c = customers[i];
        final tier = c['tier'] ?? 'Bronze';
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _tierColor(tier),
              child: Text((c['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c['phone'] ?? '-'} · ${c['loyalty_points'] ?? 0} poin · ${formatRupiah((c['total_spent'] as num? ?? 0).toDouble())}'),
                if (c['is_send_wa'] == true)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.message, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text('WA Struk Aktif', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
              onSelected: (v) {
                if (v == 'edit') _showForm(context, c);
                if (v == 'delete') _delete(c['id']);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Customer'),
        content: const Text('Yakin ingin menghapus customer ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(dioProvider).delete('customers/$id');
        ref.read(customerManagementProvider.notifier).fetchCustomers();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer dihapus')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showForm(BuildContext context, Map<String, dynamic>? c) {
    showDialog(
      context: context,
      builder: (ctx) => _CustomerFormDialog(
        customer: c,
        onSaved: () {
          ref.read(customerManagementProvider.notifier).fetchCustomers();
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _CustomerFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? customer;
  final VoidCallback onSaved;
  const _CustomerFormDialog({this.customer, required this.onSaved});

  @override
  ConsumerState<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isSendWA = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameCtrl.text = widget.customer!['name'] ?? '';
      _phoneCtrl.text = widget.customer!['phone'] ?? '';
      _emailCtrl.text = widget.customer!['email'] ?? '';
      _addressCtrl.text = widget.customer!['address'] ?? '';
      _isSendWA = widget.customer!['is_send_wa'] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Tambah Customer' : 'Edit Customer'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telepon', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kirim Struk ke WA'),
                subtitle: const Text('Kirim detil belanja otomatis via WhatsApp', style: TextStyle(fontSize: 11)),
                value: _isSendWA,
                onChanged: (v) => setState(() => _isSendWA = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
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
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'address': _addressCtrl.text,
        'is_send_wa': _isSendWA,
      };
      if (widget.customer != null) {
        await dio.put('customers/${widget.customer!['id']}', data: data);
      } else {
        await dio.post('customers', data: data);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
