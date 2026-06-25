import 'package:flutter/foundation.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/medication/domain/entities/medicamento.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';
import 'package:medisync/features/medication/domain/usecases/add_medicamento_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/list_medicamentos_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/remove_medicamento_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/update_medicamento_usecase.dart';

class ScheduleState {
  final bool isLoading;
  final List<Medicamento> medications;
  final Failure? failure;
  final bool saveSuccess;

  const ScheduleState({
    this.isLoading = false,
    this.medications = const [],
    this.failure,
    this.saveSuccess = false,
  });

  ScheduleState copyWith({
    bool? isLoading,
    List<Medicamento>? medications,
    Failure? failure,
    bool clearFailure = false,
    bool? saveSuccess,
  }) =>
      ScheduleState(
        isLoading: isLoading ?? this.isLoading,
        medications: medications ?? this.medications,
        failure: clearFailure ? null : (failure ?? this.failure),
        saveSuccess: saveSuccess ?? this.saveSuccess,
      );
}

class ScheduleViewModel extends ChangeNotifier {
  final ListMedicamentosUseCase _listUC;
  final AddMedicamentoUseCase _addUC;
  final UpdateMedicamentoUseCase _updateUC;
  final RemoveMedicamentoUseCase _removeUC;

  ScheduleState _state = const ScheduleState();
  ScheduleState get state => _state;

  ScheduleViewModel({
    required this._listUC,
    required this._addUC,
    required this._updateUC,
    required this._removeUC,
  });

  void _update(ScheduleState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> loadMedications() async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _listUC(const NoParams());
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (list) => _update(_state.copyWith(isLoading: false, medications: list)),
    );
  }

  Future<void> addMedication(AddMedicamentoParams params) async {
    _update(_state.copyWith(
        isLoading: true, clearFailure: true, saveSuccess: false));
    final result = await _addUC(params);
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (med) {
        final updated = [..._state.medications, med];
        _update(_state.copyWith(
            isLoading: false, medications: updated, saveSuccess: true));
      },
    );
  }

  Future<void> updateMedication(UpdateMedicamentoParams params) async {
    _update(_state.copyWith(
        isLoading: true, clearFailure: true, saveSuccess: false));
    final result = await _updateUC(params);
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (med) {
        final updated =
            _state.medications.map((m) => m.id == med.id ? med : m).toList();
        _update(_state.copyWith(
            isLoading: false, medications: updated, saveSuccess: true));
      },
    );
  }

  Future<void> removeMedication(int id) async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _removeUC(id);
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (_) {
        final updated =
            _state.medications.where((m) => m.id != id).toList();
        _update(_state.copyWith(
            isLoading: false, medications: updated, saveSuccess: true));
      },
    );
  }

  void clearFailure() => _update(_state.copyWith(clearFailure: true));
  void clearSuccess() => _update(_state.copyWith(saveSuccess: false));
}
