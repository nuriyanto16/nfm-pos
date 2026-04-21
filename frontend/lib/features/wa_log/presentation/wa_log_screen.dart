import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/pagination_controls.dart';

final waLogProvider = StateNotifierProvider<_WALogNotifier, _WALogState>((ref) {
  return _WALogNotifier(ref.read(dioProvider));
});

class _WALogState {
  final List<dynamic> logs;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final int totalRows;

  _WALogState({
    this.logs = const [],
    this.isLoading = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRows = 0,
  });

  _WALogState copyWith({
    List<dynamic>? logs,
    bool? isLoading,
    int? currentPage,
    int? totalPages,
    int? totalRows,
  }) {
    return _WALogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRows: totalRows ?? this.totalRows,
    );
  }
}

class _WALogNotifier extends StateNotifier<_WALogState> {
  final Dio _dio;
  _WALogNotifier(this._dio) : super(_WALogState()) {
    fetchLogs();
  }

  Future<void> fetchLogs({int page = 1}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _dio.get('wa-logs', queryParameters: {
        'page': page,
        'limit': 15,
      });
      state = state.copyWith(
        logs: response.data['data'],
        currentPage: response.data['current_page'],
        totalPages: response.data['total_pages'],
        totalRows: response.data['total_rows'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

class WALogScreen extends ConsumerWidget {
  const WALogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waLogProvider);
    final notifier = ref.read(waLogProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Pengiriman WhatsApp')),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final log = state.logs[index];
                final date = DateTime.parse(log['created_at']);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: log['status'] == 'Success' 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                      child: Icon(
                        log['status'] == 'Success' ? Icons.check : Icons.error_outline,
                        color: log['status'] == 'Success' ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(log['phone'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${DateFormat('dd MMM yyyy HH:mm').format(date)} · Order #${log['order_id']}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pesan Terkirim:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(log['message'], style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          PaginationControls(
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            totalRows: state.totalRows,
            onPageChanged: (page) => notifier.fetchLogs(page: page),
          ),
        ],
      ),
    );
  }
}
