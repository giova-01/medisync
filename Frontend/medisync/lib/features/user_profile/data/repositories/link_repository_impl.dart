import 'package:dio/dio.dart';
import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/user_profile/data/datasources/remote/link_remote_datasource.dart';
import 'package:medisync/features/user_profile/domain/entities/vinculo.dart';
import 'package:medisync/features/user_profile/domain/repositories/link_repository.dart';

class LinkRepositoryImpl implements LinkRepository {
  final LinkRemoteDataSource _remote;

  LinkRepositoryImpl({required this._remote});

  @override
  Future<Either<Failure, Vinculo>> requestLink(
      RequestLinkParams params) async {
    try {
      final dto = await _remote.requestLink(params);
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(_serverFailure(e.message));
    } on DioException catch (e) {
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  @override
  Future<Either<Failure, Vinculo>> respondLink(
      RespondLinkParams params) async {
    try {
      final dto = await _remote.respondLink(params);
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(_serverFailure(e.message));
    } on DioException catch (e) {
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  @override
  Future<Either<Failure, List<Vinculo>>> listLinks() async {
    try {
      final dtos = await _remote.listLinks();
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(_serverFailure(e.message));
    } on DioException catch (e) {
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  @override
  Future<Either<Failure, void>> revokeLink(int vinculoId) async {
    try {
      await _remote.revokeLink(vinculoId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(_serverFailure(e.message));
    } on DioException catch (e) {
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  Failure _serverFailure(String code) => switch (code) {
        'EMAIL_NOT_FOUND' =>
          const ServerFailure('No existe un paciente con ese correo electrónico.'),
        'VINCULO_NOT_FOUND' =>
          const ServerFailure('El vínculo no fue encontrado.'),
        _ => ServerFailure(code),
      };

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
