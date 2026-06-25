import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/vital_signs/domain/entities/signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/entities/tipo_signo_vital.dart';

class GetHistoryParams {
  final TipoSignoVital tipo;
  final DateTime from;
  final DateTime to;
  const GetHistoryParams({required this.tipo, required this.from, required this.to});
}

abstract interface class VitalSignsRepository {
  Future<Either<Failure, List<SignoVital>>> getLatestReadings();
  Future<Either<Failure, List<SignoVital>>> getHistory(GetHistoryParams params);
  Stream<SignoVital> watchLiveReadings();
}
