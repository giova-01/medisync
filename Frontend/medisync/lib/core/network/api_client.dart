import 'package:dio/dio.dart';
import 'auth_interceptor.dart';
import 'token_local_datasource.dart';

/// Central HTTP client. All features inject this to make API calls.
class ApiClient {
  late final Dio _dio;

  ApiClient({
    required TokenLocalDataSource tokenDS,
    required String baseUrl,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.addAll([
      AuthInterceptor(tokenDS: tokenDS),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {dynamic body, Map<String, dynamic>? query}) =>
      _dio.post<T>(path, data: body, queryParameters: query);

  Future<Response<T>> put<T>(String path, {dynamic body}) =>
      _dio.put<T>(path, data: body);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}
