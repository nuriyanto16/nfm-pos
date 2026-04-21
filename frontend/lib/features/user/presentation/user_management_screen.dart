import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

// ─── Providers ───────────────────────────────────────────────────────────────
final roleListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('roles');
  if (response.data is Map && response.data.containsKey('rows')) {
    return response.data['rows'] as List<dynamic>;
  }
  return response.data as List<dynamic>;
});

final userListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('users');
  if (response.data is Map && response.data.containsKey('rows')) {
    return response.data['rows'] as List<dynamic>;
  }
  return response.data as List<dynamic>;
});

final branchListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('branches', queryParameters: {'limit': 100});
  if (response.data is Map && response.data.containsKey('rows')) {
    return response.data['rows'] as List<dynamic>;
  }
  return response.data as List<dynamic>;
});

// ─── User Management Screen ───────────────────────────────────────────────────
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen User')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(context, null),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah User'),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) => LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 700) {
              return _buildTable(users, colorScheme);
            }
            return _buildList(users, colorScheme);
          },
        ),
      ),
    );
  }

  Widget _buildTable(List users, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(colorScheme.surfaceVariant),
          columns: const [
            DataColumn(label: Text('Nama Lengkap')),
            DataColumn(label: Text('Username')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Cabang')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: users.map<DataRow>((u) {
            final isActive = u['is_active'] == true;
            return DataRow(cells: [
              DataCell(Text(u['full_name'] ?? '-')),
              DataCell(Text(u['username'] ?? '')),
              DataCell(Chip(
                label: Text(u['role']?['name'] ?? 'N/A', style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              )),
              DataCell(Text(u['branch']?['name'] ?? 'Global')),
              DataCell(Switch(value: isActive, onChanged: (_) => _toggleActive(u))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showUserForm(context, u)),
                  IconButton(icon: const Icon(Icons.lock_outline, size: 20), onPressed: () => _showChangePassword(context, u)),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                    onPressed: () => _deleteUser(u['id']),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList(List users, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        final isActive = u['is_active'] == true;
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text((u['username'] ?? '?')[0].toUpperCase())),
            title: Text(u['full_name'] ?? u['username']),
            subtitle: Text('${u['role']?['name'] ?? 'No Role'} · ${u['branch']?['name'] ?? 'Global'} · ${isActive ? 'Aktif' : 'Nonaktif'}'),
            trailing: PopupMenuButton(itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: const Text('Edit')),
              PopupMenuItem(value: 'password', child: const Text('Ganti Password')),
              PopupMenuItem(value: 'delete', child: const Text('Hapus')),
            ], onSelected: (v) {
              if (v == 'edit') _showUserForm(context, u);
              if (v == 'password') _showChangePassword(context, u);
              if (v == 'delete') _deleteUser(u['id']);
            }),
          ),
        );
      },
    );
  }

  Future<void> _toggleActive(Map user) async {
    try {
      final dio = ref.read(dioProvider);
      final newStatus = !(user['is_active'] == true);
      await dio.put('users/${user['id']}', data: {'is_active': newStatus});
      ref.invalidate(userListProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus User'),
        content: const Text('Yakin ingin menghapus user ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final dio = ref.read(dioProvider);
        await dio.delete('users/$id');
        ref.invalidate(userListProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User dihapus')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showUserForm(BuildContext context, Map<String, dynamic>? user) {
    showDialog(
      context: context,
      builder: (ctx) => _UserFormDialog(
        user: user,
        onSaved: () {
          ref.invalidate(userListProvider);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showChangePassword(BuildContext context, Map<String, dynamic> user) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ganti Password: ${user['username']}'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password Baru (min 6 karakter)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (controller.text.length < 6) return;
              try {
                final dio = ref.read(dioProvider);
                await dio.put('users/${user['id']}/password', data: {'password': controller.text});
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
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

// ─── User Form Dialog ─────────────────────────────────────────────────────────
class _UserFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? user;
  final VoidCallback onSaved;

  const _UserFormDialog({this.user, required this.onSaved});

  @override
  ConsumerState<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  int? _selectedRoleId;
  int? _selectedBranchId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _fullNameController.text = widget.user!['full_name'] ?? '';
      _usernameController.text = widget.user!['username'] ?? '';
      _selectedRoleId = widget.user!['role_id'];
      _selectedBranchId = widget.user!['branch_id'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(roleListProvider);
    final isEdit = widget.user != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit User' : 'Tambah User'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username *', border: OutlineInputBorder()),
                enabled: !isEdit,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              if (!isEdit) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password *', border: OutlineInputBorder()),
                  validator: (v) => !isEdit && v!.length < 6 ? 'Min 6 karakter' : null,
                ),
              ],
              const SizedBox(height: 12),
              rolesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading roles'),
                data: (roles) => DropdownButtonFormField<int>(
                  value: _selectedRoleId,
                  decoration: const InputDecoration(labelText: 'Role *', border: OutlineInputBorder()),
                  items: roles.map<DropdownMenuItem<int>>((r) => DropdownMenuItem(value: r['id'], child: Text(r['name']))).toList(),
                  onChanged: (v) => setState(() => _selectedRoleId = v),
                  validator: (v) => v == null ? 'Pilih role' : null,
                ),
              ),
              const SizedBox(height: 12),
              ref.watch(branchListProvider).when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading branches'),
                data: (branches) => DropdownButtonFormField<int>(
                  value: _selectedBranchId,
                  decoration: const InputDecoration(labelText: 'Cabang (Opsional)', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Global / Semua Cabang')),
                    ...branches.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']))).toList(),
                  ],
                  onChanged: (v) => setState(() => _selectedBranchId = v),
                ),
              ),
            ],
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
      if (widget.user != null) {
        await dio.put('users/${widget.user!['id']}', data: {
          'full_name': _fullNameController.text,
          'role_id': _selectedRoleId,
          'branch_id': _selectedBranchId,
        });
      } else {
        await dio.post('users', data: {
          'full_name': _fullNameController.text,
          'username': _usernameController.text,
          'password': _passwordController.text,
          'role_id': _selectedRoleId,
          'branch_id': _selectedBranchId,
        });
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─── Role Management Screen ───────────────────────────────────────────────────
class RoleManagementScreen extends ConsumerStatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  ConsumerState<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends ConsumerState<RoleManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(roleListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Role')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoleForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Role'),
      ),
      body: rolesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (roles) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: roles.length,
          itemBuilder: (context, i) {
            final role = roles[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.shield_outlined)),
                title: Text(role['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(role['description'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showRoleForm(context, role)),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                      onPressed: () => _deleteRole(role['id']),
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

  Future<void> _deleteRole(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Role'),
        content: const Text('Yakin ingin menghapus role ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final dio = ref.read(dioProvider);
        await dio.delete('roles/$id');
        ref.invalidate(roleListProvider);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showRoleForm(BuildContext context, Map<String, dynamic>? role) {
    final nameCtrl = TextEditingController(text: role?['name'] ?? '');
    final descCtrl = TextEditingController(text: role?['description'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(role == null ? 'Tambah Role' : 'Edit Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Role *', border: OutlineInputBorder())),
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
                final data = {'name': nameCtrl.text, 'description': descCtrl.text};
                if (role != null) {
                  await dio.put('roles/${role['id']}', data: data);
                } else {
                  await dio.post('roles', data: data);
                }
                ref.invalidate(roleListProvider);
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
