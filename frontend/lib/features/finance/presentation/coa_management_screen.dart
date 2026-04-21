import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

class CoaManagementScreen extends ConsumerStatefulWidget {
  const CoaManagementScreen({super.key});

  @override
  ConsumerState<CoaManagementScreen> createState() => _CoaManagementScreenState();
}

class _CoaManagementScreenState extends ConsumerState<CoaManagementScreen> {
  final List<String> _accountTypes = ['Asset', 'Liability', 'Equity', 'Revenue', 'Expense'];
  
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart of Accounts'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder(
        future: ref.read(dioProvider).get('finance/coa'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final List accounts = snapshot.data?.data ?? [];

          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final acc = accounts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getAccountColor(acc['type']),
                  child: Text(acc['code'][0], style: const TextStyle(color: Colors.white)),
                ),
                title: Text('${acc['code']} - ${acc['name']}'),
                subtitle: Text(acc['type']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showAccountDialog(context, acc)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteAccount(acc['id'])),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountDialog(context),
        label: const Text('Tambah Akun'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAccountDialog(BuildContext context, [Map<String, dynamic>? account]) {
    final codeCtrl = TextEditingController(text: account?['code']);
    final nameCtrl = TextEditingController(text: account?['name']);
    final descCtrl = TextEditingController(text: account?['description']);
    String selectedType = account?['type'] ?? _accountTypes[0];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(account == null ? 'Tambah Akun' : 'Edit Akun'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Kode Akun')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Akun')),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: _accountTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => selectedType = v!,
                decoration: const InputDecoration(labelText: 'Tipe Akun'),
              ),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final data = {
                'code': codeCtrl.text,
                'name': nameCtrl.text,
                'type': selectedType,
                'description': descCtrl.text,
              };
              final dio = ref.read(dioProvider);
              if (account == null) {
                await dio.post('finance/coa', data: data);
              } else {
                await dio.put('finance/coa/${account['id']}', data: data);
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

  Future<void> _deleteAccount(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(dioProvider).delete('finance/coa/$id');
      _refresh();
    }
  }

  Color _getAccountColor(String type) {
    switch (type) {
      case 'Asset': return Colors.green;
      case 'Liability': return Colors.red;
      case 'Equity': return Colors.orange;
      case 'Revenue': return Colors.blue;
      case 'Expense': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
