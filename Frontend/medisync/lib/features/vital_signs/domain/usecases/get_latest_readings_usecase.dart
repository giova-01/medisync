import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/vital_signs/domain/entities/signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/repositories/vital_signs_repository.dart';

class GetLatestReadingsUseCase implements UseCase<List<SignoVital>, NoParams> {
  final VitalSignsRepository _repository;
  GetLatestReadingsUseCase(this._repository);

  @override
  Future<Either<Failure, List<SignoVital>>> call(NoParams params) =>
      _repository.getLatestReadings();
}
