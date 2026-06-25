/// Minimal interface consumed by [AuthInterceptor] to attach / clear JWT tokens.
/// Implemented by [AuthLocalDataSourceImpl] in the auth feature.
abstract interface class TokenLocalDataSource {
  Future<String?> readToken();
  Future<void> clearToken();
}
