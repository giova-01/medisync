import 'package:dio/dio.dart';
import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/medication/data/datasources/local/med_local_datasource.dart';
import 'package:medisync/features/medication/data/datasources/remote/med_remote_datasource.dart';
import 'package:medisync/features/medication/domain/entities/medicamento.dart';
import 'package:medisync/features/medication/domain/entities/toma.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final MedRemoteDataSource _remote;
  final MedLocalDataSource _local;

  MedicationRepositoryImpl({required this._remote, required this._local});

  @override
  Future<Either<Failure, List<Medicamento>>> listMedications() async {
    try {
      final dtos = await _remote.listMedications();
      _local.cacheMedications(dtos);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      final cached = _local.getCachedMedications();
      if (cached != null) return Right(cached.map((d) => d.toEntity()).toList());
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  @override
  Future<Either<Failure, List<Toma>>> getDailyIntakes(DateTime date) async {
    try {
      final dtos = await _remote.getDailyIntakes(date);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      return Left(_dioFailure(e));
    } catch (_) {
      return const Left(NetworkFailure('Error de conexión inesperado.'));
    }
  }

  @override
  Future<Either<Failure, Toma>> confirmIntake(int id) async {
    try {
      final dto = await _remote.confirmIntake(id);
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
  Future<Either<Failure, Toma>> postponeIntake(int id) async {
    try {
      final dto = await _remote.postponeIntake(id);
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
  Future<Either<Failure, Medicamento>> addMedication(
      AddMedicamentoParams params) async {
    try {
      final dto = await _remote.addMedication(params);
      _local.clearCache();
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
  Future<Either<Failure, Medicamento>> updateMedication(
      UpdateMedicamentoParams params) async {
    try {
      final dto = await _remote.updateMedication(params);
      _local.clearCache();
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
  Future<Either<Failure, void>> removeMedication(int id) async {
    try {
      await _remote.removeMedication(id);
      _local.clearCache();
      return const Right(null);
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
    return ServerFailure(
        msg ?? 'Error del servidor. Intentá de nuevo más tarde.');
  }
}
