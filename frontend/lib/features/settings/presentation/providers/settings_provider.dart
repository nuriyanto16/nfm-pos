import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(dioProvider).get('settings');
  return res.data as Map<String, dynamic>;
});
