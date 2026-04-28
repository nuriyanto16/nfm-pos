import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class FloatingChatbot extends StatefulWidget {
  const FloatingChatbot({super.key});

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot> {
  bool _isExpanded = false;
  final String _viewId = 'chatbot-iframe';

  @override
  void initState() {
    super.initState();
    
    if (kIsWeb) {
      final String chatbotBaseUrl = dotenv.env['CHATBOT_URL']?.replaceAll('/api/', '/') ?? 'http://127.0.0.1:5000/';
      
      // Register the IFrame only on Web
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => html.IFrameElement()
          ..src = chatbotBaseUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..id = 'chatbot-frame',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not web, don't show the chatbot as it relies on IFrame
    if (!kIsWeb) return const SizedBox.shrink();

    return Stack(
      children: [
        if (_isExpanded)
          Positioned(
            right: 20,
            bottom: 90,
            child: Material(
              elevation: 20,
              shadowColor: Colors.black45,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: 420,
                height: 650,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white24,
                            radius: 16,
                            child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'NFM Assistant',
                              style: TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => setState(() => _isExpanded = false),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      child: HtmlElementView(viewType: 'chatbot-iframe'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(_isExpanded ? Icons.close : Icons.chat_bubble_outline, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
