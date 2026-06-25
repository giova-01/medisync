import 'package:dio/dio.dart';
import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/auth/domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  AuthRepositoryImpl({
    required this._remote,
    required this._local,
  });

  @override
  Future<Either<Failure, Usuario>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _remote.login(email, password);
      await _local.saveToken(response.token);
      await _local.saveUser(response.user);
      return Right(response.user.toEntity());
    } on ServerException catch (e) {
      return Left(_serverFailure(e.message));
    } on DioException catch (e) {
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  @override
  Future<Either<Failure, Usuario>> register(RegisterParams params) async {
    try {
      final response = await _remote.register(params);
      await _local.saveToken(response.token);
      await _local.saveUser(response.user);
      return Right(response.user.toEntity());
    } on ServerException catch (e) {
      return Left(_serverFailure(e.message));
    } on DioException catch (e) {
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  @override
  Future<Either<Failure, void>> recoverPassword(String email) async {
    try {
      await _remote.recoverPassword(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _local.clearAll();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Usuario?>> currentUser() async {
    try {
      final dto = await _local.readUser();
      return Right(dto?.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Failure _serverFailure(String code) => switch (code) {
        'INVALID_CREDENTIALS' =>
          const ServerFailure('Correo o contraseña incorrectos.'),
        'ACCOUNT_LOCKED' => const ServerFailure(
            'Tu cuenta fue bloqueada 30 minutos por múltiples intentos fallidos.',
          ),
        'EMAIL_ALREADY_EXISTS' =>
          const ServerFailure('Ya existe una cuenta con ese correo electrónico.'),
        _ => ServerFailure(code),
      };

  Failure _dioFailure(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(
          'Sin conexión. Verificá tu internet e intentá nuevamente.');
    }
    final status = e.response?.statusCode;
    if (status == 401) return const ServerFailure('Sesión expirada. Iniciá sesión nuevamente.');
    if (status == 423) {
      return const ServerFailure(
          'Tu cuenta fue bloqueada 30 minutos por múltiples intentos fallidos.');
    }
    final msg = e.response?.data?['detail'] as String?;
    return ServerFailure(msg ?? 'Error del servidor. Intentá de nuevo más tarde.');
  }
}
