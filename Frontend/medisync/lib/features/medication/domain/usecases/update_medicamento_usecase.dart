import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/medication/domain/entities/medicamento.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';

class UpdateMedicamentoUseCase implements UseCase<Medicamento, UpdateMedicamentoParams> {
  final MedicationRepository _repository;
  UpdateMedicamentoUseCase(this._repository);

  @override
  Future<Either<Failure, Medicamento>> call(UpdateMedicamentoParams params) =>
      _repository.updateMedication(params);
}
