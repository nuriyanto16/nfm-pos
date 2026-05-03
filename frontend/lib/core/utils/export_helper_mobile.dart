import 'package:flutter/foundation.dart';

void exportToExcel(String csv, String fileName) {
  // On mobile, we could save to local storage or share
  // For now, we just print to debug console as a fallback
  debugPrint('Mobile export not fully implemented: $fileName');
  debugPrint(csv);
}
