import 'dart:ui_web' as ui_web;
import 'dart:js_util' as js_util;

void registerChatbotWeb(String viewId, String url) {
  // Use platformViewRegistry from dart:ui_web
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) {
      // Create iframe using raw JS interop via dart:js_util
      // This avoids depending on package:web which causes mobile build issues
      final document = js_util.getProperty(js_util.globalThis, 'document');
      final iframe = js_util.callMethod(document, 'createElement', ['iframe']);
      
      js_util.setProperty(iframe, 'src', url);
      js_util.setProperty(iframe, 'id', 'chatbot-frame');
      
      final style = js_util.getProperty(iframe, 'style');
      js_util.setProperty(style, 'border', 'none');
      js_util.setProperty(style, 'width', '100%');
      js_util.setProperty(style, 'height', '100%');
      
      return iframe as Object;
    },
  );
}
