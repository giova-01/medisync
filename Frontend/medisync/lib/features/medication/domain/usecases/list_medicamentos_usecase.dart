import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/medication/domain/entities/medicamento.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';

class ListMedicamentosUseCase implements UseCase<List<Medicamento>, NoParams> {
  final MedicationRepository _repository;
  ListMedicamentosUseCase(this._repository);

  @override
  Future<Either<Failure, List<Medicamento>>> call(NoParams params) =>
      _repository.listMedications();
}
