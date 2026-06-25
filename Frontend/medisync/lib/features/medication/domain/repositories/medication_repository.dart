import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/medication/domain/entities/medicamento.dart';
import 'package:medisync/features/medication/domain/entities/toma.dart';

class GetDailyIntakesParams {
  final DateTime date;
  const GetDailyIntakesParams(this.date);
}

class AddMedicamentoParams {
  final String nombre;
  final String dosis;
  final int frecuenciaHoras;
  final DateTime fechaInicio;
  final DateTime? fechaFin;

  const AddMedicamentoParams({
    required this.nombre,
    required this.dosis,
    required this.frecuenciaHoras,
    required this.fechaInicio,
    this.fechaFin,
  });
}

class UpdateMedicamentoParams {
  final int id;
  final String nombre;
  final String dosis;
  final int frecuenciaHoras;
  final DateTime fechaInicio;
  final DateTime? fechaFin;

  const UpdateMedicamentoParams({
    required this.id,
    required this.nombre,
    required this.dosis,
    required this.frecuenciaHoras,
    required this.fechaInicio,
    this.fechaFin,
  });
}

abstract interface class MedicationRepository {
  Future<Either<Failure, List<Medicamento>>> listMedications();
  Future<Either<Failure, Medicamento>> addMedication(AddMedicamentoParams params);
  Future<Either<Failure, Medicamento>> updateMedication(UpdateMedicamentoParams params);
  Future<Either<Failure, void>> removeMedication(int id);
  Future<Either<Failure, List<Toma>>> getDailyIntakes(DateTime date);
  Future<Either<Failure, Toma>> confirmIntake(int id);
  Future<Either<Failure, Toma>> postponeIntake(int id);
}
