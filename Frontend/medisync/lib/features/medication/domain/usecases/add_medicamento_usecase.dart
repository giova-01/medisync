import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/medication/domain/entities/medicamento.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';

class AddMedicamentoUseCase implements UseCase<Medicamento, AddMedicamentoParams> {
  final MedicationRepository _repository;
  AddMedicamentoUseCase(this._repository);

  @override
  Future<Either<Failure, Medicamento>> call(AddMedicamentoParams params) =>
      _repository.addMedication(params);
}
