import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:image_picker/image_picker.dart';
import '../../../core/network/dio_client.dart';

final companyListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('companies');
  return response.data as List<dynamic>;
});

class CompanyManagementScreen extends ConsumerWidget {
  const CompanyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companyListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Perusahaan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCompanyForm(context, ref, null),
        icon: const Icon(Icons.business),
        label: const Text('Tambah Perusahaan'),
      ),
      body: companiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (companies) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: companies.length,
          itemBuilder: (context, i) {
            final co = companies[i];
            final logoUrl = co['logo_url'];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: (logoUrl != null && logoUrl.isNotEmpty)
                      ? NetworkImage('${ref.watch(imageBaseUrlProvider)}$logoUrl')
                      : null,
                  child: (logoUrl == null || logoUrl.isEmpty) ? const Icon(Icons.corporate_fare) : null,
                ),
                title: Text(co['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${co['code']} · ${co['phone'] ?? '-'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showCompanyForm(context, ref, co)),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                      onPressed: () => _deleteCompany(context, ref, co['id']),
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

  Future<void> _deleteCompany(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Perusahaan'),
        content: const Text('Yakin ingin menghapus perusahaan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(dioProvider).delete('companies/$id');
        ref.invalidate(companyListProvider);
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCompanyForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? co) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CompanyFormDialog(
        company: co,
        onSaved: () {
          ref.invalidate(companyListProvider);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _CompanyFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? company;
  final VoidCallback onSaved;
  const _CompanyFormDialog({this.company, required this.onSaved});

  @override
  ConsumerState<_CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends ConsumerState<_CompanyFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  String? _logoUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.company?['name'] ?? '');
    _codeCtrl = TextEditingController(text: widget.company?['code'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.company?['phone'] ?? '');
    _addressCtrl = TextEditingController(text: widget.company?['address'] ?? '');
    _logoUrl = widget.company?['logo_url'];
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400);
      if (pickedFile == null) return;

      setState(() => _isUploading = true);
      final bytes = await pickedFile.readAsBytes();
      final formData = dio_pkg.FormData.fromMap({
        'image': dio_pkg.MultipartFile.fromBytes(bytes, filename: pickedFile.name),
      });

      final dio = ref.read(dioProvider);
      final response = await dio.post('companies/upload', data: formData);
      if (response.statusCode == 200) {
        setState(() => _logoUrl = response.data['url']);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload gagal: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.company == null ? 'Tambah Perusahaan' : 'Edit Perusahaan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _isUploading ? null : _pickAndUploadLogo,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : _logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(
                              '${ref.watch(imageBaseUrlProvider)}$_logoUrl',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 30),
                              Text('Upload Logo', style: TextStyle(fontSize: 10)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Perusahaan *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Kode *', border: OutlineInputBorder()), enabled: widget.company == null),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Telepon', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder()), maxLines: 2),
          ],
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
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      final data = {
        'name': _nameCtrl.text,
        'code': _codeCtrl.text,
        'phone': _phoneCtrl.text,
        'address': _addressCtrl.text,
        'logo_url': _logoUrl,
      };
      if (widget.company != null) {
        await dio.put('companies/${widget.company!['id']}', data: data);
      } else {
        await dio.post('companies', data: data);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
