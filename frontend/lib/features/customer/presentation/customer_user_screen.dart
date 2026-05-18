import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/skeleton.dart';

final customerUserListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('customer-users');
  return response.data as List<dynamic>;
});

class CustomerUserScreen extends ConsumerStatefulWidget {
  const CustomerUserScreen({super.key});

  @override
  ConsumerState<CustomerUserScreen> createState() => _CustomerUserScreenState();
}

class _CustomerUserScreenState extends ConsumerState<CustomerUserScreen> {
  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(customerUserListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Registrasi Online'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(customerUserListProvider),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ListSkeleton(itemCount: 10),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Belum ada customer yang registrasi.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user['is_active'] ? Colors.green : Colors.grey,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(user['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${user['username']} • ${user['phone'] ?? '-'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!user['is_active'])
                        const Badge(label: Text('Nonaktif'), backgroundColor: Colors.red),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editUser(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addUser() {
    _showUserForm();
  }

  void _editUser(dynamic user) {
    _showUserForm(user: user);
  }

  void _showUserForm({dynamic user}) {
    final isEdit = user != null;
    final fullNameController = TextEditingController(text: isEdit ? user['full_name'] : '');
    final usernameController = TextEditingController(text: isEdit ? user['username'] : '');
    final emailController = TextEditingController(text: isEdit ? user['email'] : '');
    final phoneController = TextEditingController(text: isEdit ? user['phone'] : '');
    final passwordController = TextEditingController();
    bool isActive = isEdit ? user['is_active'] : true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Customer User' : 'Tambah Customer User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  enabled: !isEdit,
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Ganti Password (Kosongkan jika tidak)' : 'Password',
                  ),
                  obscureText: true,
                ),
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: isActive,
                  onChanged: (val) => setState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final dio = ref.read(dioProvider);
                final data = {
                  'full_name': fullNameController.text,
                  'username': usernameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'is_active': isActive,
                };
                if (passwordController.text.isNotEmpty) {
                  data['password'] = passwordController.text;
                }

                try {
                  if (isEdit) {
                    await dio.put('customer-users/${user['id']}', data: data);
                  } else {
                    await dio.post('customer-users', data: data);
                  }
                  ref.invalidate(customerUserListProvider);
                  if (mounted) Navigator.pop(ctx);
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
        await dio.delete('customer-users/$id');
        ref.invalidate(customerUserListProvider);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
