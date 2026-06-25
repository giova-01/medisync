import 'package:medisync/core/network/api_client.dart';
import 'package:medisync/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:medisync/features/medication/data/models/medicamento_dto.dart';
import 'package:medisync/features/medication/data/models/toma_dto.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';

abstract interface class MedRemoteDataSource {
  Future<List<MedicamentoDto>> listMedications();
  Future<MedicamentoDto> addMedication(AddMedicamentoParams params);
  Future<MedicamentoDto> updateMedication(UpdateMedicamentoParams params);
  Future<void> removeMedication(int id);
  Future<List<TomaDto>> getDailyIntakes(DateTime date);
  Future<TomaDto> confirmIntake(int id);
  Future<TomaDto> postponeIntake(int id);
}

class MedRemoteDataSourceMock implements MedRemoteDataSource {
  static const _delay = Duration(milliseconds: 800);

  final List<MedicamentoDto> _medications = const [
    MedicamentoDto(
      id: 1,
      nombre: 'Enalapril',
      dosis: '10mg',
      frecuenciaHoras: 12,
      fechaInicio: '2026-01-01',
    ),
    MedicamentoDto(
      id: 2,
      nombre: 'Metformina',
      dosis: '500mg',
      frecuenciaHoras: 8,
      fechaInicio: '2026-02-01',
    ),
    MedicamentoDto(
      id: 3,
      nombre: 'Atorvastatina',
      dosis: '20mg',
      frecuenciaHoras: 24,
      fechaInicio: '2025-12-01',
    ),
  ];

  List<MedicamentoDto> _mutableMedications = [];

  MedRemoteDataSourceMock() {
    _mutableMedications = List.from(_medications);
  }

  @override
  Future<List<MedicamentoDto>> listMedications() async {
    await Future.delayed(_delay);
    return List.from(_mutableMedications);
  }

  @override
  Future<List<TomaDto>> getDailyIntakes(DateTime date) async {
    await Future.delayed(_delay);
    final tomas = <TomaDto>[];
    int tomaId = 1;

    for (final med in _mutableMedications) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final intakesPerDay = (24 / med.frecuenciaHoras).ceil();

      for (int i = 0; i < intakesPerDay; i++) {
        final hora = startOfDay.add(Duration(hours: med.frecuenciaHoras * i));
        tomas.add(TomaDto(
          id: tomaId++,
          fechaProgramada: hora.toIso8601String(),
          estado: 'pendiente',
          horarioId: (med.id * 10) + i,
          nombreMedicamento: med.nombre,
          dosis: med.dosis,
        ));
      }
    }

    tomas.sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));
    return tomas;
  }

  @override
  Future<TomaDto> confirmIntake(int id) async {
    await Future.delayed(_delay);
    return TomaDto(
      id: id,
      fechaProgramada: DateTime.now().toIso8601String(),
      fechaConfirmada: DateTime.now().toIso8601String(),
      estado: 'confirmada',
      horarioId: id * 10,
      nombreMedicamento: 'Medicamento',
      dosis: '—',
    );
  }

  @override
  Future<TomaDto> postponeIntake(int id) async {
    await Future.delayed(_delay);
    return TomaDto(
      id: id,
      fechaProgramada:
          DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
      estado: 'pospuesta',
      horarioId: id * 10,
      nombreMedicamento: 'Medicamento',
      dosis: '—',
    );
  }

  @override
  Future<MedicamentoDto> addMedication(AddMedicamentoParams params) async {
    await Future.delayed(_delay);
    final nuevo = MedicamentoDto(
      id: 100 + _mutableMedications.length,
      nombre: params.nombre,
      dosis: params.dosis,
      frecuenciaHoras: params.frecuenciaHoras,
      fechaInicio: params.fechaInicio.toIso8601String().substring(0, 10),
      fechaFin: params.fechaFin?.toIso8601String().substring(0, 10),
    );
    _mutableMedications.add(nuevo);
    return nuevo;
  }

  @override
  Future<MedicamentoDto> updateMedication(UpdateMedicamentoParams params) async {
    await Future.delayed(_delay);
    final updated = MedicamentoDto(
      id: params.id,
      nombre: params.nombre,
      dosis: params.dosis,
      frecuenciaHoras: params.frecuenciaHoras,
      fechaInicio: params.fechaInicio.toIso8601String().substring(0, 10),
      fechaFin: params.fechaFin?.toIso8601String().substring(0, 10),
    );
    final idx = _mutableMedications.indexWhere((m) => m.id == params.id);
    if (idx != -1) _mutableMedications[idx] = updated;
    return updated;
  }

  @override
  Future<void> removeMedication(int id) async {
    await Future.delayed(_delay);
    _mutableMedications.removeWhere((m) => m.id == id);
  }
}

// ---------------------------------------------------------------------------
// Real implementation backed by the FastAPI backend (see
// Backend/app/routers/medication.py). The domain layer has no concept of
// "which patient" — a Cuidador/Profesional always operates on their single
// linked patient — so non-Paciente sessions resolve `patient_id` here via
// GET /links before calling the patient-scoped endpoints.
// ---------------------------------------------------------------------------
class MedRemoteDataSourceImpl implements MedRemoteDataSource {
  final ApiClient _api;
  final AuthLocalDataSource _authLocal;

  MedRemoteDataSourceImpl(this._api, this._authLocal);

  Future<int?> _resolveLinkedPatientId() async {
    final user = await _authLocal.readUser();
    if (user == null || user.tipoPerfil == 'paciente') return null;
    final response = await _api.get<List<dynamic>>('/links');
    for (final raw in response.data ?? []) {
      final link = raw as Map<String, dynamic>;
      if (link['estado'] == 'aceptado') return link['id_paciente'] as int;
    }
    return null;
  }

  String _dateOnly(DateTime d) => d.toIso8601String().substring(0, 10);

  @override
  Future<List<MedicamentoDto>> listMedications() async {
    final patientId = await _resolveLinkedPatientId();
    final response = await _api.get<List<dynamic>>(
      '/medications',
      query: patientId != null ? {'patient_id': patientId} : null,
    );
    return (response.data ?? [])
        .map((e) => MedicamentoDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TomaDto>> getDailyIntakes(DateTime date) async {
    final patientId = await _resolveLinkedPatientId();
    final response = await _api.get<List<dynamic>>(
      '/intakes',
      query: {
        'date': _dateOnly(date),
        'patient_id': ?patientId,
      },
    );
    return (response.data ?? [])
        .map((e) => TomaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TomaDto> confirmIntake(int id) async {
    final response = await _api.post<Map<String, dynamic>>('/intakes/$id/confirm');
    return TomaDto.fromJson(response.data!);
  }

  @override
  Future<TomaDto> postponeIntake(int id) async {
    final response = await _api.post<Map<String, dynamic>>('/intakes/$id/postpone');
    return TomaDto.fromJson(response.data!);
  }

  @override
  Future<MedicamentoDto> addMedication(AddMedicamentoParams params) async {
    final patientId = await _resolveLinkedPatientId();
    final response = await _api.post<Map<String, dynamic>>(
      '/medications',
      query: patientId != null ? {'patient_id': patientId} : null,
      body: _medicationBody(
        nombre: params.nombre,
        dosis: params.dosis,
        frecuenciaHoras: params.frecuenciaHoras,
        fechaInicio: params.fechaInicio,
        fechaFin: params.fechaFin,
      ),
    );
    return MedicamentoDto.fromJson(response.data!);
  }

  @override
  Future<MedicamentoDto> updateMedication(UpdateMedicamentoParams params) async {
    final response = await _api.put<Map<String, dynamic>>(
      '/medications/${params.id}',
      body: _medicationBody(
        nombre: params.nombre,
        dosis: params.dosis,
        frecuenciaHoras: params.frecuenciaHoras,
        fechaInicio: params.fechaInicio,
        fechaFin: params.fechaFin,
      ),
    );
    return MedicamentoDto.fromJson(response.data!);
  }

  @override
  Future<void> removeMedication(int id) async {
    await _api.delete<void>('/medications/$id');
  }

  Map<String, dynamic> _medicationBody({
    required String nombre,
    required String dosis,
    required int frecuenciaHoras,
    required DateTime fechaInicio,
    required DateTime? fechaFin,
  }) => {
        'nombre': nombre,
        'dosis': dosis,
        'frecuencia_horas': frecuenciaHoras,
        'fecha_inicio': _dateOnly(fechaInicio),
        if (fechaFin != null) 'fecha_fin': _dateOnly(fechaFin),
      };
}
