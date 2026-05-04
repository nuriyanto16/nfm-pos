import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: dotenv.env['BASE_URL'] ?? 'http://localhost:8080/api/',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ));

  return dio;
});

final imageBaseUrlProvider = Provider<String>((ref) {
  final baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:8080/api';
  return baseUrl.split('/api')[0];
});

final chatbotUrlProvider = Provider<String>((ref) {
  // Prioritize CHATBOT_URL from .env
  String? envUrl = dotenv.env['CHATBOT_URL'];
  
  if (envUrl != null && envUrl.isNotEmpty) {
    return envUrl.endsWith('/') ? envUrl : '$envUrl/';
  }

  // Fallback for local development
  const String defaultUrl = 'http://localhost:5000/';
  return defaultUrl;
});

final chatbotDioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(chatbotUrlProvider);
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Add logging interceptor for debugging in APK
  dio.interceptors.add(LogInterceptor(
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
  ));

  return dio;
});
