import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'branch_provider.dart';

class BranchManagementScreen extends ConsumerWidget {
  const BranchManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Cabang')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBranchForm(context, ref, null),
        icon: const Icon(Icons.add_business),
        label: const Text('Tambah Cabang'),
      ),
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (branches) {
          if (branches.isEmpty) {
            return const Center(child: Text('Belum ada cabang.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: branches.length,
            itemBuilder: (context, index) {
              final b = branches[index];
              final isActive = b['is_active'] == true;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive ? colorScheme.primary.withOpacity(0.1) : colorScheme.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store_rounded, 
                      color: isActive ? colorScheme.primary : colorScheme.outline,
                    ),
                  ),
                  title: Text(b['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${b['code']} · ${b['address'] ?? "-"}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'AKTIF' : 'NONAKTIF',
                          style: TextStyle(
                            fontSize: 9, 
                            fontWeight: FontWeight.bold, 
                            color: isActive ? Colors.green : Colors.red
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'edit') _showBranchForm(context, ref, b);
                      if (val == 'delete') _deleteBranch(context, ref, b['id']);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit')])),
                      PopupMenuItem(
                        value: 'delete', 
                        child: Row(children: [Icon(Icons.delete_outline, size: 20, color: colorScheme.error), const SizedBox(width: 12), Text('Hapus', style: TextStyle(color: colorScheme.error))])
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showBranchForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? branch) {
    showDialog(
      context: context,
      builder: (ctx) => _BranchFormDialog(
        branch: branch,
        onSaved: () {
          ref.invalidate(branchProvider);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _deleteBranch(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Cabang'),
        content: const Text('Yakin ingin menghapus cabang ini? Data yang terikat mungkin akan terpengaruh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(dioProvider).delete('branches/$id');
        ref.invalidate(branchProvider);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _BranchFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? branch;
  final VoidCallback onSaved;
  const _BranchFormDialog({this.branch, required this.onSaved});

  @override
  ConsumerState<_BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends ConsumerState<_BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _openTimeCtrl = TextEditingController(text: '08:00');
  final _closeTimeCtrl = TextEditingController(text: '22:00');
  bool _isActive = true;
  bool _isSaving = false;
  String _selectedPosType = 'resto';

  @override
  void initState() {
    super.initState();
    if (widget.branch != null) {
      _nameCtrl.text = widget.branch!['name'] ?? '';
      _codeCtrl.text = widget.branch!['code'] ?? '';
      _addressCtrl.text = widget.branch!['address'] ?? '';
      _phoneCtrl.text = widget.branch!['phone'] ?? '';
      _emailCtrl.text = widget.branch!['email'] ?? '';
      _openTimeCtrl.text = widget.branch!['open_time'] != null ? widget.branch!['open_time'].toString().substring(0, 5) : '08:00';
      _closeTimeCtrl.text = widget.branch!['close_time'] != null ? widget.branch!['close_time'].toString().substring(0, 5) : '22:00';
      _isActive = widget.branch!['is_active'] ?? true;
      _selectedPosType = widget.branch!['pos_type'] ?? 'resto';
    }
  }

  Future<void> _selectTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initialTime = TimeOfDay(
      hour: parts.length > 0 ? int.tryParse(parts[0]) ?? 8 : 8,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        ctrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.branch == null ? 'Tambah Cabang' : 'Edit Cabang'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Cabang *', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
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
                      setState(() => _selectedPosType = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(labelText: 'Kode Cabang *', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telepon', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _openTimeCtrl,
                        readOnly: true,
                        onTap: () => _selectTime(_openTimeCtrl),
                        decoration: const InputDecoration(
                          labelText: 'Jam Buka', 
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _closeTimeCtrl,
                        readOnly: true,
                        onTap: () => _selectTime(_closeTimeCtrl),
                        decoration: const InputDecoration(
                          labelText: 'Jam Tutup', 
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time_filled),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Status Aktif'),
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
          child: _isSaving ? const CircularProgressIndicator() : const Text('Simpan'),
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
        'code': _codeCtrl.text,
        'address': _addressCtrl.text,
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'open_time': _openTimeCtrl.text,
        'close_time': _closeTimeCtrl.text,
        'is_active': _isActive,
        'pos_type': _selectedPosType,
      };
      if (widget.branch != null) {
        await dio.put('branches/${widget.branch!['id']}', data: data);
      } else {
        await dio.post('branches', data: data);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
