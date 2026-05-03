import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // Added for MediaType
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/pagination_controls.dart';
import '../../branch/presentation/branch_provider.dart';
import 'table_provider.dart';

class TableManagementScreen extends ConsumerWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tableManagementProvider);
    final notifier = ref.read(tableManagementProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Meja')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTableForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Meja'),
      ),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: state.items.isEmpty && !state.isLoading
              ? const Center(child: Text('Tidak ada meja ditemukan'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.items.length,
                  itemBuilder: (context, i) {
                    final t = state.items[i];
                    final isOccupied = t['status'] == 'Digunakan';
                    return Card(
                      elevation: 2,
                      shadowColor: isOccupied ? colorScheme.error.withOpacity(0.2) : Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isOccupied ? colorScheme.error.withOpacity(0.5) : colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showTableForm(context, ref, t),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              t['image_url'] != null && t['image_url'].toString().isNotEmpty
                                  ? Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            '${ref.read(dioProvider).options.baseUrl.replaceAll('/api/', '')}${t['image_url']}',
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                            },
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.table_restaurant, 
                                              size: 40, 
                                              color: isOccupied ? colorScheme.error : colorScheme.primary.withOpacity(0.5)
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: (isOccupied ? colorScheme.error : colorScheme.primary).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.table_restaurant, 
                                        color: isOccupied ? colorScheme.error : colorScheme.primary,
                                        size: 32,
                                      ),
                                    ),
                              const SizedBox(height: 8),
                              Text('Meja ${t['table_number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Kapasitas: ${t['capacity']}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(t['status'] ?? 'Kosong', 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOccupied ? colorScheme.error : Colors.green)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.qr_code),
                                tooltip: 'Tampilkan Stiker QR',
                                onPressed: () {
                                  _showTableQR(context, t);
                                },
                              )
                            ],
                          ),
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

  void _showTableForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? table) {
    showDialog(
      context: context,
      builder: (ctx) => _TableFormDialog(
        table: table,
        onSaved: () {
          ref.read(tableManagementProvider.notifier).fetchTables();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showTableQR(BuildContext context, Map<String, dynamic> table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('QR Code Meja ${table['table_number']}'),
        content: SizedBox(
          width: 300,
          height: 350,
          child: Column(
            children: [
              QrImageView(
                data: 'https://product.nfmtech.my.id/#/order?table=${table['id']}&branch=${table['branch_id']}',
                version: QrVersions.auto,
                size: 250.0,
              ),
              const SizedBox(height: 16),
              const Text('Scan untuk melakukan pemesanan', style: TextStyle(fontSize: 12)),
              Text('ID: ${table['id']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );
  }
}

class _TableFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? table;
  final VoidCallback onSaved;
  const _TableFormDialog({this.table, required this.onSaved});

  @override
  ConsumerState<_TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends ConsumerState<_TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  int? _selectedBranchId;
  String? _status;
  String? _imageUrl;
  bool _isSaving = false;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _numberCtrl.text = widget.table!['table_number'] ?? '';
      _capacityCtrl.text = widget.table!['capacity']?.toString() ?? '2';
      _floorCtrl.text = widget.table!['floor'] ?? '1';
      _selectedBranchId = widget.table!['branch_id'];
      _status = widget.table!['status'] ?? 'Kosong';
      _imageUrl = widget.table!['image_url'];
    } else {
      _status = 'Kosong';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<String?> _uploadImage(int tableId) async {
    if (_imageFile == null) return _imageUrl;
    try {
      final dio = ref.read(dioProvider);
      MultipartFile file;
      if (kIsWeb) {
        final bytes = await _imageFile!.readAsBytes();
        file = MultipartFile.fromBytes(
          bytes,
          filename: _imageFile!.name,
          contentType: MediaType('image', 'png'), // Changed to standard MediaType
        );
      } else {
        file = await MultipartFile.fromFile(_imageFile!.path, filename: _imageFile!.name);
      }
      
      final formData = FormData.fromMap({'image': file});
      final res = await dio.post('tables/$tableId/image', data: formData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gambar berhasil diunggah!')));
      }
      return res.data['image_url'];
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal unggah gambar: $e')));
      }
      return _imageUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchProvider);

    return AlertDialog(
      title: Text(widget.table == null ? 'Tambah Meja' : 'Edit Meja'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _numberCtrl,
              decoration: const InputDecoration(labelText: 'Nomor Meja *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kapasitas *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _floorCtrl,
              decoration: const InputDecoration(labelText: 'Lantai / Area', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const Text('Foto Meja (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _imageFile != null
                    ? (kIsWeb ? Image.network(_imageFile!.path, fit: BoxFit.cover) : Image.file(File(_imageFile!.path), fit: BoxFit.cover))
                    : (_imageUrl != null && _imageUrl!.isNotEmpty
                        ? Image.network('${ref.read(dioProvider).options.baseUrl.replaceAll('/api/', '')}$_imageUrl', fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.add_a_photo, size: 30, color: Colors.grey), Text('Upload Foto Meja')],
                          )),
              ),
            ),
            const SizedBox(height: 12),
            branchesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (branches) => DropdownButtonFormField<int>(
                value: _selectedBranchId,
                decoration: const InputDecoration(labelText: 'Cabang *', border: OutlineInputBorder()),
                items: branches.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']))).toList(),
                onChanged: (v) => setState(() => _selectedBranchId = v),
                validator: (v) => v == null ? 'Pilih cabang' : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        if (widget.table != null)
           TextButton(
             onPressed: () => _delete(widget.table!['id']),
             child: const Text('Hapus', style: TextStyle(color: Colors.red)),
           ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _delete(int id) async {
    try {
      await ref.read(dioProvider).delete('tables/$id');
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      final data = {
        'table_number': _numberCtrl.text,
        'capacity': int.tryParse(_capacityCtrl.text) ?? 2,
        'floor': _floorCtrl.text.isEmpty ? '1' : _floorCtrl.text,
        'branch_id': _selectedBranchId,
        'status': widget.table?['status'] ?? 'Kosong',
      };
      if (widget.table != null) {
        final res = await dio.put('tables/${widget.table!['id']}', data: data);
        await _uploadImage(widget.table!['id']);
      } else {
        final res = await dio.post('tables', data: data);
        if (res.data['id'] != null) {
          await _uploadImage(res.data['id']);
        }
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
