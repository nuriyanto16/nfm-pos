import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

class ChatbotHistoryScreen extends ConsumerStatefulWidget {
  const ChatbotHistoryScreen({super.key});

  @override
  ConsumerState<ChatbotHistoryScreen> createState() => _ChatbotHistoryScreenState();
}

class _ChatbotHistoryScreenState extends ConsumerState<ChatbotHistoryScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;
  String? _error;
  
  // Search & Pagination States
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalChats = 0;
  final int _limit = 10; // 10 per page as in the screenshot

  // Active chat selection index
  int _selectedLogIndex = 0;

  // In-memory feedback store (logId -> feedbackType)
  final Map<int, String> _feedback = {};

  @override
  void initState() {
    super.initState();
    _fetchPage(1);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _selectedLogIndex = 0; // Reset active selection on search
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int page) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(chatbotDioProvider);
      final offset = (page - 1) * _limit;
      final response = await dio.get('api/logs', queryParameters: {
        'limit': _limit,
        'offset': offset,
      });
      
      final data = response.data as Map<String, dynamic>;
      final newLogs = data['logs'] as List;
      _totalChats = data['total'] ?? 0;

      setState(() {
        _logs = newLogs;
        _currentPage = page;
        _isLoading = false;
        if (_selectedLogIndex >= _logs.length) {
          _selectedLogIndex = 0;
        }
      });
    } catch (e) {
      final baseUrl = ref.read(chatbotUrlProvider);
      setState(() {
        _error = 'Gagal memuat history chat: $e';
        _isLoading = false;
      });
    }
  }

  // Parses name and contact info (e.g. "John Doe (john@email.com)")
  Map<String, String> _parseUserName(String? rawName) {
    if (rawName == null || rawName.isEmpty) return {'name': 'Guest', 'contact': '-'};
    final regex = RegExp(r'^([^(]+)(?:\(([^)]+)\))?');
    final match = regex.firstMatch(rawName);
    if (match != null) {
      final name = match.group(1)?.trim() ?? 'Guest';
      final contact = match.group(2)?.trim() ?? '-';
      return {'name': name, 'contact': contact};
    }
    return {'name': rawName, 'contact': '-'};
  }

  String _getInitials(String name) {
    final clean = name.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    final parts = clean.split(' ');
    if (parts.isEmpty || clean.isEmpty) return 'US';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  int get _totalPages => (_totalChats / _limit).ceil() == 0 ? 1 : (_totalChats / _limit).ceil();

  // Filters current page logs client-side by query
  List<dynamic> get _filteredLogs {
    if (_searchQuery.isEmpty) return _logs;
    return _logs.where((log) {
      final nameInfo = _parseUserName(log['user_name']);
      final name = nameInfo['name']!.toLowerCase();
      final contact = nameInfo['contact']!.toLowerCase();
      final msg = (log['message'] ?? '').toString().toLowerCase();
      final reply = (log['reply'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || contact.contains(q) || msg.contains(q) || reply.contains(q);
    }).toList();
  }

  dynamic get _selectedLog {
    final list = _filteredLogs;
    if (list.isEmpty || _selectedLogIndex >= list.length) return null;
    return list[_selectedLogIndex];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'CONVERSATION LOG',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: ElevatedButton.icon(
              onPressed: () => _fetchPage(_currentPage),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1100;
          final isTablet = constraints.maxWidth >= 720 && constraints.maxWidth < 1100;

          if (_isLoading && _logs.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
          }

          if (_error != null && _logs.isEmpty) {
            return _buildErrorWidget(theme);
          }

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Panel: Logs & search
                Container(
                  width: 350,
                  color: theme.cardColor,
                  child: _buildLeftPane(theme, isDark),
                ),
                Container(width: 1, color: theme.dividerColor),
                // Middle Panel: Conversation detail bubble
                Expanded(
                  child: _buildMiddlePane(theme, isDark),
                ),
                Container(width: 1, color: theme.dividerColor),
                // Right Panel: Summary stats & details
                SizedBox(
                  width: 320,
                  child: _buildRightPane(theme, isDark),
                ),
              ],
            );
          } else if (isTablet) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 340,
                  color: theme.cardColor,
                  child: _buildLeftPane(theme, isDark),
                ),
                Container(width: 1, color: theme.dividerColor),
                Expanded(
                  child: _buildMiddlePane(theme, isDark),
                ),
              ],
            );
          } else {
            return _buildMobileView(theme, isDark);
          }
        },
      ),
    );
  }

  // ─── LEFT PANE: Logs List ────────────────────────────────────────────────
  Widget _buildLeftPane(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'History Chat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Pantau log pesan user, respon asisten AI, kesesuaian jawaban, serta analisis token per sesi percakapan.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        // Search Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama, ID, pesan...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
            ),
          ),
        ),
        // Chat Logs List
        Expanded(
          child: _filteredLogs.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ditemukan data.',
                    style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredLogs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                  itemBuilder: (context, index) {
                    final log = _filteredLogs[index];
                    final isSelected = index == _selectedLogIndex;
                    final parsed = _parseUserName(log['user_name']);
                    final platform = log['platform'] ?? 'WEB';
                    
                    DateTime? parsedTime;
                    try { parsedTime = DateTime.parse(log['timestamp']); } catch(_) {}
                    final timeStr = parsedTime != null ? DateFormat('dd MMMM').format(parsedTime.toLocal()) : '';

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedLogIndex = index;
                        });
                      },
                      child: Container(
                        color: isSelected
                            ? theme.primaryColor.withOpacity(0.12)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.primaryColor.withOpacity(isSelected ? 0.2 : 0.08),
                              child: Text(
                                _getInitials(parsed['name']!),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          parsed['name']!,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeStr,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log['message'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: platform.toUpperCase() == 'WEB'
                                              ? theme.primaryColor.withOpacity(0.1)
                                              : const Color(0xFF22C55E).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          platform.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: platform.toUpperCase() == 'WEB'
                                                ? theme.primaryColor
                                                : const Color(0xFF22C55E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Pagination Controls
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _currentPage > 1 ? () => _fetchPage(_currentPage - 1) : null,
                child: const Text('Prev'),
              ),
              Text(
                'Hal. $_currentPage / $_totalPages',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _currentPage < _totalPages ? () => _fetchPage(_currentPage + 1) : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── MIDDLE PANE: Active Chat ────────────────────────────────────────────
  Widget _buildMiddlePane(ThemeData theme, bool isDark) {
    final log = _selectedLog;
    if (log == null) {
      return Center(
        child: Text(
          'Pilih salah satu percakapan di samping untuk melihat detail',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
        ),
      );
    }

    final parsed = _parseUserName(log['user_name']);
    final platform = log['platform'] ?? 'WEB';
    final logId = log['id'] as int;
    final currentFeedback = _feedback[logId];

    DateTime? parsedTime;
    try { parsedTime = DateTime.parse(log['timestamp']); } catch(_) {}
    final formattedTime = parsedTime != null ? DateFormat('HH:mm').format(parsedTime.toLocal()) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Text(
                  _getInitials(parsed['name']!),
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parsed['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID sesi: nfm-session-${log['id']}',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7), fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  platform.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.primaryColor),
                ),
              ),
            ],
          ),
        ),
        // Conversation log body
        Expanded(
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 1. User Message (Blue Bubble aligned to right)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 550),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              parsed['name']!.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            log['message'] ?? '',
                            style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 14, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedTime,
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        )
                      ],
                    ),
                  ),
                ),
                // 2. Bot Message Card (Styled grey card aligned left)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NFM ASSISTANT BOT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.primaryColor, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          log['reply'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              formattedTime,
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                            // Feedback Rating Buttons
                            Row(
                              children: [
                                _feedbackButton(
                                  label: 'Jawaban Sesuai',
                                  icon: Icons.thumb_up_alt_outlined,
                                  color: const Color(0xFF22C55E),
                                  isSelected: currentFeedback == 'sesuai',
                                  onTap: () {
                                    setState(() {
                                      _feedback[logId] = 'sesuai';
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _feedbackButton(
                                  label: 'Jawaban Tidak Sesuai',
                                  icon: Icons.thumb_down_alt_outlined,
                                  color: const Color(0xFFEF4444),
                                  isSelected: currentFeedback == 'tidak_sesuai',
                                  onTap: () {
                                    setState(() {
                                      _feedback[logId] = 'tidak_sesuai';
                                    });
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tokens: ${log['input_tokens'] ?? 0} in / ${log['output_tokens'] ?? 0} out',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _feedbackButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? color : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── RIGHT PANE: Summary Stats ───────────────────────────────────────────
  Widget _buildRightPane(ThemeData theme, bool isDark) {
    final log = _selectedLog;
    if (log == null) return Container(color: isDark ? const Color(0xFF1E293B) : Colors.white);

    final parsed = _parseUserName(log['user_name']);
    final platform = log['platform'] ?? 'WEB';
    
    DateTime? parsedTime;
    try { parsedTime = DateTime.parse(log['timestamp']); } catch(_) {}
    final activeTimeStr = parsedTime != null ? DateFormat('dd/M/yyyy, HH.mm.ss').format(parsedTime.toLocal()) : '';

    final inputTokens = log['input_tokens'] ?? 0;
    final outputTokens = log['output_tokens'] ?? 0;
    final totalTokens = inputTokens + outputTokens;

    // Feedback metrics count for current page
    int countSesuai = _logs.where((l) => _feedback[l['id']] == 'sesuai').length;
    int countTidakSesuai = _logs.where((l) => _feedback[l['id']] == 'tidak_sesuai').length;
    int countBelumReviewed = _logs.where((l) => !_feedback.containsKey(l['id'])).length;

    return Container(
      color: theme.cardColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          // Section 1: Customer Profile
          _buildRightPaneSection(
            title: 'PROFIL PELANGGAN',
            children: [
              _buildRightPaneRow('Nama', parsed['name']!, isBoldValue: true),
              _buildRightPaneRow('Kontak', parsed['contact']!),
              _buildRightPaneRow('Saluran', platform.toUpperCase()),
            ],
          ),
          const SizedBox(height: 24),
          // Section 2: Conversation Details
          _buildRightPaneSection(
            title: 'DETAIL PERCAKAPAN',
            children: [
              _buildRightPaneRow('ID Sesi', 'nfm-session-${log['id']}', isCode: true),
              _buildRightPaneRow('Terakhir Aktif', activeTimeStr),
              _buildRightPaneRow('Total Pesan', '2 pesan', isBoldValue: true),
            ],
          ),
          const SizedBox(height: 24),
          // Section 3: Token Statistics
          _buildRightPaneSection(
            title: 'STATISTIK TOKEN',
            children: [
              _buildRightPaneRow('Input Tokens', inputTokens.toString()),
              _buildRightPaneRow('Output Tokens', outputTokens.toString()),
              _buildRightPaneRow('Total Tokens', totalTokens.toString(), valueColor: theme.primaryColor, isBoldValue: true),
            ],
          ),
          const SizedBox(height: 24),
          // Section 4: Review Ratings
          _buildRightPaneSection(
            title: 'KESESUAIAN JAWABAN',
            children: [
              _buildRightPaneRow('Sesuai', countSesuai.toString(), valueColor: const Color(0xFF22C55E), isBoldValue: true),
              _buildRightPaneRow('Tidak Sesuai', countTidakSesuai.toString(), valueColor: const Color(0xFFEF4444), isBoldValue: true),
              _buildRightPaneRow('Belum di-review', countBelumReviewed.toString(), isBoldValue: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightPaneSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildRightPaneRow(String label, String value, {bool isBoldValue = false, Color? valueColor, bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? (isBoldValue ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                fontFamily: isCode ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE VIEW: Staged Screens ─────────────────────────────────────────
  Widget _buildMobileView(ThemeData theme, bool isDark) {
    // Basic mobile fallback: list of chats, tap navigates to detailed dialog
    final list = _filteredLogs;
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final log = list[index];
        final parsed = _parseUserName(log['user_name']);
        
        DateTime? parsedTime;
        try { parsedTime = DateTime.parse(log['timestamp']); } catch(_) {}
        final formattedTime = parsedTime != null ? DateFormat('HH:mm').format(parsedTime.toLocal()) : '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
            child: Text(_getInitials(parsed['name']!)),
          ),
          title: Text(parsed['name']!),
          subtitle: Text(log['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(formattedTime),
          onTap: () {
            // Push custom Dialog to display details
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  insetPadding: const EdgeInsets.all(16),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(parsed['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TANYA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[500])),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(log['message'] ?? '', style: const TextStyle(fontSize: 14)),
                                ),
                                const SizedBox(height: 16),
                                Text('JAWAB:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[500])),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(log['reply'] ?? '', style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _fetchPage(1), child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
