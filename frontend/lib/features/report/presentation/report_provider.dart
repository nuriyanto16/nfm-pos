import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final financialReportProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, paramsKey) async {
  final parts = paramsKey.split('|');
  final params = {
    'start_date': parts[0],
    'end_date': parts[1],
  };
  final dio = ref.read(dioProvider);
  final response = await dio.get('reports/financial', queryParameters: params);
  return response.data as Map<String, dynamic>;
});
