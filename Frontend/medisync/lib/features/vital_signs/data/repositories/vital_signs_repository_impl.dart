import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/vital_signs/data/datasources/remote/vitals_remote_datasource.dart';
import 'package:medisync/features/vital_signs/domain/entities/signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/repositories/vital_signs_repository.dart';

class VitalSignsRepositoryImpl implements VitalSignsRepository {
  final VitalsRemoteDataSource _remote;

  VitalSignsRepositoryImpl({required this._remote});

  @override
  Future<Either<Failure, List<SignoVital>>> getLatestReadings() async {
    try {
      final dtos = await _remote.getLatestReadings();
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on BleException catch (e) {
      return Left(BleFailure(e.message));
    } catch (_) {
      return const Left(BleFailure('No se pudieron leer los signos vitales.'));
    }
  }

  @override
  Future<Either<Failure, List<SignoVital>>> getHistory(GetHistoryParams params) async {
    try {
      final dtos = await _remote.getHistory(params);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on BleException catch (e) {
      return Left(BleFailure(e.message));
    } catch (_) {
      return const Left(BleFailure('No se pudo cargar el historial.'));
    }
  }

  @override
  Stream<SignoVital> watchLiveReadings() =>
      _remote.watchLiveReadings().map((dto) => dto.toEntity());
}
