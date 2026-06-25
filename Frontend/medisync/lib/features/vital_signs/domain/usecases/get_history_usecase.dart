import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/vital_signs/domain/entities/signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/repositories/vital_signs_repository.dart';

class GetHistoryUseCase implements UseCase<List<SignoVital>, GetHistoryParams> {
  final VitalSignsRepository _repository;
  GetHistoryUseCase(this._repository);

  @override
  Future<Either<Failure, List<SignoVital>>> call(GetHistoryParams params) =>
      _repository.getHistory(params);
}
