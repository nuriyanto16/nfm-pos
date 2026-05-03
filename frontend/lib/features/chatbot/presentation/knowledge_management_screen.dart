import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KnowledgeManagementScreen extends ConsumerStatefulWidget {
  const KnowledgeManagementScreen({super.key});

  @override
  ConsumerState<KnowledgeManagementScreen> createState() => _KnowledgeManagementScreenState();
}

class _KnowledgeManagementScreenState extends ConsumerState<KnowledgeManagementScreen> {
  List<String> _files = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000';
      final chatbotUrl = rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
      final dio = Dio();
      final response = await dio.get('${chatbotUrl}api/knowledge');
      setState(() {
        _files = List<String>.from(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat daftar knowledge: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFile(String filename) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Knowledge'),
        content: Text('Apakah Anda yakin ingin menghapus file "$filename"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final rawUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000';
      final chatbotUrl = rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
      final dio = Dio();
      await dio.delete('${chatbotUrl}api/knowledge/$filename');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File berhasil dihapus')));
      _fetchFiles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus file: $e')));
    }
  }

  void _showEditor([String? filename]) async {
    String content = "";
    String name = filename ?? "";
    bool isEditing = filename != null;
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isEditing) {
      try {
        final rawUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000';
        final chatbotUrl = rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
        final dio = Dio();
        final response = await dio.get('${chatbotUrl}api/knowledge/$filename');
        content = response.data['content'] ?? "";
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat isi file: $e')));
        return;
      }
    }

    final nameController = TextEditingController(text: name);
    final contentController = TextEditingController(text: content);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit_note_rounded : Icons.note_add_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(isEditing ? 'Edit Knowledge' : 'Tambah Knowledge'),
          ],
        ),
        content: SizedBox(
          width: isMobile ? double.infinity : 700,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama File',
                  hintText: 'contoh: info_pos_mobile.txt',
                  prefixIcon: const Icon(Icons.file_present_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                readOnly: isEditing,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: isMobile ? 12 : 15,
                decoration: InputDecoration(
                  labelText: 'Isi Knowledge',
                  hintText: 'Tuliskan informasi produk, promo, atau panduan di sini...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty || contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan isi tidak boleh kosong')));
                return;
              }
              try {
                final rawUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000';
                final chatbotUrl = rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
                final dio = Dio();
                await dio.post('${chatbotUrl}api/knowledge', data: {
                  'filename': nameController.text.endsWith('.txt') ? nameController.text : '${nameController.text}.txt',
                  'content': contentController.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Knowledge berhasil disimpan')));
                _fetchFiles();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan knowledge: $e')));
              }
            },
            child: const Text('Simpan Knowledge'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base Chatbot'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchFiles),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(),
        label: const Text('Tambah Knowledge'),
        icon: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final filename = _files[index];
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
                            color: colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.auto_stories_rounded, color: colorScheme.primary),
                        ),
                        title: Text(filename, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Dokumen Knowledge Base (.txt)',
                          style: TextStyle(fontSize: 12, color: colorScheme.outline),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) {
                            if (val == 'edit') _showEditor(filename);
                            if (val == 'delete') _deleteFile(filename);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit', 
                              child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit')])
                            ),
                            PopupMenuItem(
                              value: 'delete', 
                              child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), const SizedBox(width: 12), Text('Hapus', style: TextStyle(color: Colors.red))])
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
