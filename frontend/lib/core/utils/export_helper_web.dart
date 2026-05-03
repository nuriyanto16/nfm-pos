import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_util' as js_util;

void exportToExcel(String csv, String fileName) {
  final bytes = utf8.encode(csv);
  
  // Use JS interop to create blob and trigger download
  final blobParts = js_util.newObject();
  js_util.setProperty(blobParts, 'type', 'text/csv');
  
  // Convert List<int> to JS Uint8Array
  final uint8List = Uint8List.fromList(bytes);
  
  final blob = js_util.callConstructor(
    js_util.getProperty(js_util.globalThis, 'Blob'),
    [[uint8List], blobParts]
  );
  
  final url = js_util.callMethod(
    js_util.getProperty(js_util.globalThis, 'URL'),
    'createObjectURL',
    [blob]
  );
  
  final anchor = js_util.callMethod(
    js_util.getProperty(js_util.globalThis, 'document'),
    'createElement',
    ['a']
  );
  
  js_util.setProperty(anchor, 'href', url);
  js_util.setProperty(anchor, 'download', fileName);
  js_util.callMethod(anchor, 'click', []);
  
  js_util.callMethod(
    js_util.getProperty(js_util.globalThis, 'URL'),
    'revokeObjectURL',
    [url]
  );
}
