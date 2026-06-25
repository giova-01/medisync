import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/medication/domain/entities/toma.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';

class ConfirmIntakeUseCase implements UseCase<Toma, int> {
  final MedicationRepository _repository;
  ConfirmIntakeUseCase(this._repository);

  @override
  Future<Either<Failure, Toma>> call(int params) =>
      _repository.confirmIntake(params);
}
