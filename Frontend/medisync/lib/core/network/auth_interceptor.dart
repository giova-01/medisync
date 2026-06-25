import 'package:dio/dio.dart';
import 'token_local_datasource.dart';

/// Attaches the JWT Bearer token to every outgoing request.
/// On 401 the stored token is cleared (the GoRouter redirect handles logout).
class AuthInterceptor extends Interceptor {
  final TokenLocalDataSource _tokenDS;

  AuthInterceptor({required this._tokenDS});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenDS.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _tokenDS.clearToken();
    }
    handler.next(err);
  }
}
