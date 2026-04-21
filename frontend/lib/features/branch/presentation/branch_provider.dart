import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final branchProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('branches', queryParameters: {'limit': 100});
  if (response.data is Map && response.data.containsKey('rows')) {
    return response.data['rows'] as List<dynamic>;
  }
  return response.data as List<dynamic>;
});
