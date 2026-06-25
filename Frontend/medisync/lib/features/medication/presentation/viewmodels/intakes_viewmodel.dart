import 'package:flutter/foundation.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/medication/domain/entities/toma.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';
import 'package:medisync/features/medication/domain/usecases/confirm_intake_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/get_daily_intakes_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/postpone_intake_usecase.dart';

class IntakesState {
  final bool isLoading;
  final List<Toma> tomas;
  final DateTime selectedDate;
  final Failure? failure;

  IntakesState({
    this.isLoading = false,
    this.tomas = const [],
    DateTime? selectedDate,
    this.failure,
  }) : selectedDate = selectedDate ?? DateTime.now();

  IntakesState copyWith({
    bool? isLoading,
    List<Toma>? tomas,
    DateTime? selectedDate,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      IntakesState(
        isLoading: isLoading ?? this.isLoading,
        tomas: tomas ?? this.tomas,
        selectedDate: selectedDate ?? this.selectedDate,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

class IntakesViewModel extends ChangeNotifier {
  final GetDailyIntakesUseCase _getDailyIntakesUC;
  final ConfirmIntakeUseCase _confirmUC;
  final PostponeIntakeUseCase _postponeUC;

  IntakesState _state = IntakesState();
  IntakesState get state => _state;

  IntakesViewModel({
    required this._getDailyIntakesUC,
    required this._confirmUC,
    required this._postponeUC,
  });

  void _update(IntakesState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> loadIntakes(DateTime date) async {
    _update(_state.copyWith(
        isLoading: true, clearFailure: true, selectedDate: date));
    final result = await _getDailyIntakesUC(GetDailyIntakesParams(date));
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (list) => _update(_state.copyWith(isLoading: false, tomas: list)),
    );
  }

  Future<void> confirmIntake(int id) async {
    final result = await _confirmUC(id);
    result.fold(
      (f) => _update(_state.copyWith(failure: f)),
      (toma) {
        final updated = _state.tomas.map((t) => t.id == id ? toma : t).toList();
        _update(_state.copyWith(tomas: updated));
      },
    );
  }

  Future<void> postponeIntake(int id) async {
    final result = await _postponeUC(id);
    result.fold(
      (f) => _update(_state.copyWith(failure: f)),
      (toma) {
        final updated = _state.tomas.map((t) => t.id == id ? toma : t).toList();
        _update(_state.copyWith(tomas: updated));
      },
    );
  }

  void clearFailure() => _update(_state.copyWith(clearFailure: true));
}
