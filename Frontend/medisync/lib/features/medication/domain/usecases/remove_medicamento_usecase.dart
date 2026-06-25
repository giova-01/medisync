import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';

class RemoveMedicamentoUseCase implements UseCase<void, int> {
  final MedicationRepository _repository;
  RemoveMedicamentoUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(int params) =>
      _repository.removeMedication(params);
}
