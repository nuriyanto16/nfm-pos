import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/skeleton.dart';
import 'package:intl/intl.dart';

final registrationListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('registrations');
  return response.data as List<dynamic>;
});

class RegistrationManagementScreen extends ConsumerStatefulWidget {
  const RegistrationManagementScreen({super.key});

  @override
  ConsumerState<RegistrationManagementScreen> createState() => _RegistrationManagementScreenState();
}

class _RegistrationManagementScreenState extends ConsumerState<RegistrationManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final registrationsAsync = ref.watch(registrationListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Registrasi Trial')),
      body: registrationsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ListSkeleton(itemCount: 10),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (registrations) {
          if (registrations.isEmpty) {
            return const Center(child: Text('Belum ada pendaftaran trial.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: registrations.length,
            itemBuilder: (context, i) {
              final reg = registrations[i];
              final date = DateTime.parse(reg['created_at']);
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
              
              return Card(
                child: ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(reg['status'], colorScheme),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(reg['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${reg['business_name']} · ${reg['phone']}'),
                      Text(reg['email']),
                      const SizedBox(height: 4),
                      Text('Daftar: $formattedDate', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusBadge(reg['status'], colorScheme),
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => <PopupMenuEntry>[
                          const PopupMenuItem(value: 'Pending', child: Text('Set Pending')),
                          const PopupMenuItem(value: 'Contacted', child: Text('Set Hubungi')),
                          const PopupMenuItem(value: 'Trialing', child: Text('Set Sedang Trial')),
                          const PopupMenuItem(value: 'Done', child: Text('Set Selesai')),
                          const PopupMenuDivider(),
                          const PopupMenuItem(value: 'delete', child: Text('Hapus Data', style: TextStyle(color: Colors.red))),
                        ],
                        onSelected: (val) {
                          if (val == 'delete') {
                            _deleteRegistration(reg['id']);
                          } else {
                            _updateStatus(reg['id'], val);
                          }
                        },
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

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Contacted': return Colors.blue;
      case 'Trialing': return Colors.purple;
      case 'Done': return Colors.green;
      default: return colorScheme.outline;
    }
  }

  Widget _buildStatusBadge(String status, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status, colorScheme).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status, colorScheme)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(status, colorScheme),
        ),
      ),
    );
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('registrations/$id', data: {'status': status});
      ref.invalidate(registrationListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status diupdate ke $status')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteRegistration(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin ingin menghapus data pendaftaran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final dio = ref.read(dioProvider);
        await dio.delete('registrations/$id');
        ref.invalidate(registrationListProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil dihapus')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
