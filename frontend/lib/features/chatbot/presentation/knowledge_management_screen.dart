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
      final chatbotUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000/api/';
      final dio = Dio();
      final response = await dio.get('${chatbotUrl}knowledge');
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
      final chatbotUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000/api/';
      final dio = Dio();
      await dio.delete('${chatbotUrl}knowledge/$filename');
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

    if (isEditing) {
      try {
        final chatbotUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000/api/';
        final dio = Dio();
        final response = await dio.get('${chatbotUrl}knowledge/$filename');
        content = response.data['content'] ?? "";
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat isi file: $e')));
        return;
      }
    }

    final nameController = TextEditingController(text: name);
    final contentController = TextEditingController(text: content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Knowledge' : 'Tambah Knowledge Baru'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama File (contoh: info_promo.txt)'),
                readOnly: isEditing,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 15,
                decoration: const InputDecoration(
                  labelText: 'Isi Knowledge',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                final chatbotUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000/api/';
                final dio = Dio();
                await dio.post('${chatbotUrl}knowledge', data: {
                  'filename': nameController.text,
                  'content': contentController.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Knowledge berhasil disimpan')));
                _fetchFiles();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan knowledge: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot Knowledge Management'),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final filename = _files[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.description, color: Colors.blue),
                        title: Text(filename),
                        subtitle: const Text('File Knowledge (.txt)'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showEditor(filename),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteFile(filename),
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
