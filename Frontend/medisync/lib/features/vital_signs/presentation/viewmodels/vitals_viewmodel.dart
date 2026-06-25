import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/vital_signs/domain/entities/signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/entities/tipo_signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/repositories/vital_signs_repository.dart';
import 'package:medisync/features/vital_signs/domain/usecases/get_history_usecase.dart';
import 'package:medisync/features/vital_signs/domain/usecases/get_latest_readings_usecase.dart';

class VitalsState {
  final bool isLoading;
  final Map<TipoSignoVital, SignoVital> latest;
  final List<SignoVital> history;
  final TipoSignoVital selectedTipo;
  final Failure? failure;

  const VitalsState({
    this.isLoading = false,
    this.latest = const {},
    this.history = const [],
    this.selectedTipo = TipoSignoVital.frecuenciaCardiaca,
    this.failure,
  });

  VitalsState copyWith({
    bool? isLoading,
    Map<TipoSignoVital, SignoVital>? latest,
    List<SignoVital>? history,
    TipoSignoVital? selectedTipo,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      VitalsState(
        isLoading: isLoading ?? this.isLoading,
        latest: latest ?? this.latest,
        history: history ?? this.history,
        selectedTipo: selectedTipo ?? this.selectedTipo,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

class VitalsViewModel extends ChangeNotifier {
  final VitalSignsRepository _repository;
  final GetLatestReadingsUseCase _getLatestUC;
  final GetHistoryUseCase _getHistoryUC;

  StreamSubscription<SignoVital>? _subscription;

  VitalsState _state = const VitalsState();
  VitalsState get state => _state;

  VitalsViewModel({
    required this._repository,
    required this._getLatestUC,
    required this._getHistoryUC,
  });

  void _update(VitalsState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> loadLatest() async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _getLatestUC(const NoParams());
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (readings) {
        final map = {for (final r in readings) r.tipo: r};
        _update(_state.copyWith(isLoading: false, latest: map));
      },
    );
    await loadHistory(_state.selectedTipo);
  }

  Future<void> loadHistory(TipoSignoVital tipo) async {
    final now = DateTime.now();
    final result = await _getHistoryUC(GetHistoryParams(
      tipo: tipo,
      from: now.subtract(const Duration(hours: 24)),
      to: now,
    ));
    result.fold(
      (f) => _update(_state.copyWith(failure: f)),
      (history) => _update(_state.copyWith(selectedTipo: tipo, history: history)),
    );
  }

  void selectTipo(TipoSignoVital tipo) => loadHistory(tipo);

  void startLiveUpdates() {
    _subscription?.cancel();
    _subscription = _repository.watchLiveReadings().listen(
      (signo) {
        final updatedLatest = Map<TipoSignoVital, SignoVital>.from(_state.latest);
        updatedLatest[signo.tipo] = signo;
        final updatedHistory = signo.tipo == _state.selectedTipo
            ? [..._state.history, signo]
            : _state.history;
        _update(_state.copyWith(latest: updatedLatest, history: updatedHistory));
      },
      onError: (_) => _update(_state.copyWith(
          failure: const BleFailure('Se perdió la conexión con el dispositivo.'))),
    );
  }

  void stopLiveUpdates() {
    _subscription?.cancel();
    _subscription = null;
  }

  void clearFailure() => _update(_state.copyWith(clearFailure: true));

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
