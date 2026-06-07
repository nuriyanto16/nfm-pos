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
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildPlanBadge(reg['plan'] ?? 'UMKM'),
                          _buildPosTypeBadge(reg['pos_type'] ?? 'resto'),
                          _buildPaymentBadge(reg['is_paid'] ?? false),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                          const PopupMenuItem(value: 'approve', child: Text('✅ Setujui & Buat Akun', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: reg['is_paid'] == true ? 'unpay' : 'pay',
                            child: Text(reg['is_paid'] == true ? '🔴 Tandai Belum Bayar' : '🟢 Tandai Sudah Bayar'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(value: 'pos_resto', child: Text('🖥️ Ubah ke POS Resto')),
                          const PopupMenuItem(value: 'pos_retail', child: Text('🖥️ Ubah ke POS Retail')),
                          const PopupMenuItem(value: 'pos_jasa', child: Text('🖥️ Ubah ke POS Jasa')),
                          const PopupMenuItem(value: 'pos_fashion', child: Text('🖥️ Ubah ke POS Fashion')),
                          const PopupMenuDivider(),
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
                          } else if (val == 'approve') {
                            _approveRegistration(reg['id'], reg['is_paid'] ?? false);
                          } else if (val == 'pay') {
                            _updateRegistration(reg['id'], {'is_paid': true}, 'Status pembayaran diubah ke Lunas');
                          } else if (val == 'unpay') {
                            _updateRegistration(reg['id'], {'is_paid': false}, 'Status pembayaran diubah ke Belum Bayar');
                          } else if (val == 'pos_resto') {
                            _updateRegistration(reg['id'], {'pos_type': 'resto'}, 'Jenis POS diubah ke POS Resto');
                          } else if (val == 'pos_retail') {
                            _updateRegistration(reg['id'], {'pos_type': 'retail'}, 'Jenis POS diubah ke POS Retail');
                          } else if (val == 'pos_jasa') {
                            _updateRegistration(reg['id'], {'pos_type': 'jasa'}, 'Jenis POS diubah ke POS Jasa');
                          } else if (val == 'pos_fashion') {
                            _updateRegistration(reg['id'], {'pos_type': 'fashion'}, 'Jenis POS diubah ke POS Fashion');
                          } else {
                            _updateRegistration(reg['id'], {'status': val}, 'Status diupdate ke $val');
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

  Widget _buildPlanBadge(String plan) {
    Color badgeColor = Colors.grey;
    if (plan == 'UMKM') badgeColor = Colors.teal;
    if (plan == 'Bisnis') badgeColor = Colors.indigo;
    if (plan == 'Franchise') badgeColor = Colors.deepOrange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        'Plan: $plan',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildPosTypeBadge(String posType) {
    Color badgeColor = Colors.blue;
    String label = 'POS Resto';
    if (posType == 'retail') {
      badgeColor = Colors.amber.shade800;
      label = 'POS Retail';
    } else if (posType == 'jasa') {
      badgeColor = Colors.purple;
      label = 'POS Jasa';
    } else if (posType == 'fashion') {
      badgeColor = Colors.pink;
      label = 'POS Fashion';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(bool isPaid) {
    Color badgeColor = isPaid ? Colors.green : Colors.red;
    String label = isPaid ? 'Lunas / Sudah Bayar' : 'Belum Bayar';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Future<void> _updateRegistration(int id, Map<String, dynamic> data, String successMessage) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('registrations/$id', data: data);
      ref.invalidate(registrationListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _approveRegistration(int id, bool isPaid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Persetujuan'),
        content: Text(
          isPaid 
            ? 'Sistem akan membuatkan akun Company, Branch, dan Admin User secara otomatis. Lanjutkan?'
            : 'Peringatan: Pendaftaran ini belum ditandai Lunas / Sudah Bayar.\n\nSistem akan secara otomatis menandai status pembayaran sebagai LUNAS dan membuatkan akun Company, Branch, dan Admin User. Lanjutkan?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Setujui & Buat Akun')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = ref.read(dioProvider);
        final response = await dio.post('registrations/$id/approve');
        ref.invalidate(registrationListProvider);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Berhasil!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Akun berhasil dibuat untuk: ${response.data['company']}'),
                  const SizedBox(height: 8),
                  Text('Username: ${response.data['username']}'),
                  Text('Password: ${response.data['password']}'),
                  const SizedBox(height: 8),
                  const Text('Detail akun telah dikirim ke WhatsApp user.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
