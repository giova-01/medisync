import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/medication/domain/entities/toma.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';

class GetDailyIntakesUseCase implements UseCase<List<Toma>, GetDailyIntakesParams> {
  final MedicationRepository _repository;
  GetDailyIntakesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Toma>>> call(GetDailyIntakesParams params) =>
      _repository.getDailyIntakes(params.date);
}
