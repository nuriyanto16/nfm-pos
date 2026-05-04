import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for web-only functionality
import 'chatbot_stub.dart' if (dart.library.js_util) 'chatbot_web.dart';

class FloatingChatbot extends StatefulWidget {
  const FloatingChatbot({super.key});

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final String _viewId = 'chatbot-iframe';
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  // Bottom offset: enough space to clear pagination bars (typically 48–56px tall)
  static const double _fabBottom = 80;
  static const double _fabRight = 20;
  static const double _chatWidth = 400;
  static const double _chatHeight = 600;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);

    if (kIsWeb) {
      final String rawUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000';
      final String chatbotBaseUrl = rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
      registerChatbotWeb(_viewId, chatbotBaseUrl);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // ─── Chat Window ───────────────────────────────────────────────────
        if (_isExpanded)
          Positioned(
            right: _fabRight,
            // Position chat window above the FAB with a small gap
            bottom: _fabBottom + 64,
            child: ScaleTransition(
              scale: _scaleAnim,
              alignment: Alignment.bottomRight,
              child: Material(
                elevation: 24,
                shadowColor: Colors.black38,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: _chatWidth,
                  height: _chatHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      // ── Header ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.85),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white24,
                              radius: 16,
                              child: const Icon(Icons.smart_toy_outlined,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NFM Assistant',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '● Online',
                                    style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.open_in_new,
                                  color: Colors.white70, size: 16),
                              tooltip: 'Buka di jendela baru',
                              onPressed: () {
                                final rawUrl = dotenv.env['CHATBOT_URL'] ?? 'http://127.0.0.1:5000';
                                final url = rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
                                launchUrlString(url, mode: LaunchMode.externalApplication);
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white70, size: 18),
                              tooltip: 'Refresh Chat',
                              onPressed: () {
                                // Simple way to "refresh" HtmlElementView is to toggle visibility
                                setState(() => _isExpanded = false);
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  setState(() => _isExpanded = true);
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 20),
                              onPressed: _toggle,
                            ),
                          ],
                        ),
                      ),
                      // ── IFrame ──
                      const Expanded(
                        child: HtmlElementView(viewType: 'chatbot-iframe'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ─── FAB ──────────────────────────────────────────────────────────
        Positioned(
          right: _fabRight,
          bottom: _fabBottom,
          child: Tooltip(
            message: _isExpanded ? 'Tutup Chat' : 'Tanya NFM Assistant',
            child: FloatingActionButton(
              heroTag: 'chatbot_fab',
              onPressed: _toggle,
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 8,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isExpanded ? Icons.close : Icons.chat_bubble_outline,
                  key: ValueKey(_isExpanded),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
