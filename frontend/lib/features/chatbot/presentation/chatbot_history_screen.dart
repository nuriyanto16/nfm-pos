import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class ChatbotHistoryScreen extends ConsumerStatefulWidget {
  const ChatbotHistoryScreen({super.key});

  @override
  ConsumerState<ChatbotHistoryScreen> createState() => _ChatbotHistoryScreenState();
}

class _ChatbotHistoryScreenState extends ConsumerState<ChatbotHistoryScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;
  bool _isMoreLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  int _totalChats = 0;
  final int _limit = 20;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _offset = 0;
        _logs = [];
        _hasMore = true;
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final rawUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000/api/';
      final chatbotUrl = rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
      final dio = Dio();
      final response = await dio.get('${chatbotUrl}api/logs', queryParameters: {
        'limit': _limit,
        'offset': _offset,
      });
      
      final data = response.data as Map<String, dynamic>;
      final newLogs = data['logs'] as List;
      _totalChats = data['total'] ?? 0;

      setState(() {
        _logs.addAll(newLogs);
        _isLoading = false;
        _isMoreLoading = false;
        _hasMore = _logs.length < _totalChats;
        _offset += newLogs.length;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat history chat: $e';
        _isLoading = false;
        _isMoreLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isMoreLoading || !_hasMore) return;
    setState(() => _isMoreLoading = true);
    _fetchLogs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('History Chatbot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (!_isLoading)
              Text('Total $_totalChats percakapan masuk', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchLogs(isRefresh: true),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => _fetchLogs(isRefresh: true), child: const Text('Coba Lagi')),
                  ],
                ))
              : _logs.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('Belum ada riwayat chat.', style: TextStyle(color: Colors.grey)),
                      ],
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _logs.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _logs.length) {
                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: _isMoreLoading
                                  ? CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor)
                                  : OutlinedButton.icon(
                                      onPressed: _loadMore,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Muat Lebih Banyak'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                    ),
                            ),
                          );
                        }

                        final log = _logs[index];
                        final timestamp = DateTime.parse(log['timestamp']);
                        final formattedTime = DateFormat('HH:mm').format(timestamp.toLocal());
                        final formattedDate = DateFormat('dd MMM yyyy').format(timestamp.toLocal());
                        final isTelegram = log['platform'] == 'TELEGRAM';

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                            border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                          ),
                          child: ExpansionTile(
                            shape: const RoundedRectangleBorder(side: BorderSide.none),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: (isTelegram ? Colors.blue : Colors.orange).withOpacity(0.1),
                              child: Icon(
                                isTelegram ? Icons.telegram : Icons.web,
                                color: isTelegram ? Colors.blue : Colors.orange,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              log['user_name'] ?? 'Guest',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Text(
                              '${log['message']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formattedTime, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                                Text(formattedDate, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 10),
                                    _buildDetailRow(theme, 'Tanya:', log['message'], isBot: false),
                                    const SizedBox(height: 16),
                                    _buildDetailRow(theme, 'Jawab:', log['reply'], isBot: true),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Model: ${log['model_name'] ?? '-'}', style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: Colors.grey)),
                                        Row(
                                          children: [
                                            _tokenBadge(theme, 'IN', log['input_tokens'] ?? 0, Colors.blue),
                                            const SizedBox(width: 6),
                                            _tokenBadge(theme, 'OUT', log['output_tokens'] ?? 0, Colors.green),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _tokenBadge(ThemeData theme, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(value.toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String? text, {required bool isBot}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(isBot ? Icons.smart_toy : Icons.person, size: 14, color: isBot ? theme.primaryColor : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isBot ? theme.primaryColor : Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isBot ? theme.primaryColor.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text ?? '-', style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
      ],
    );
  }

  Widget _tokenInfo(BuildContext context, String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
