import 'package:dio/dio.dart';
import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/user_profile/data/datasources/remote/profile_remote_datasource.dart';
import 'package:medisync/features/user_profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;

  ProfileRepositoryImpl({required this._remote});

  @override
  Future<Either<Failure, Usuario>> getProfile() async {
    try {
      final dto = await _remote.getProfile();
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  @override
  Future<Either<Failure, Usuario>> updateProfile(
      UpdateProfileParams params) async {
    try {
      final dto = await _remote.updateProfile(params);
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  Failure _dioFailure(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(
          'Sin conexión. Verificá tu internet e intentá nuevamente.');
    }
    final msg = e.response?.data?['detail'] as String?;
    return ServerFailure(msg ?? 'Error del servidor. Intentá de nuevo más tarde.');
  }
}
