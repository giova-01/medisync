import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/alerts/domain/entities/alerta.dart';
import 'package:medisync/features/alerts/domain/entities/severidad_alerta.dart';
import 'package:medisync/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:medisync/features/alerts/domain/usecases/get_alerts_usecase.dart';
import 'package:medisync/features/alerts/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:medisync/features/alerts/domain/usecases/mark_alert_as_read_usecase.dart';

class AlertsState {
  final bool isLoading;
  final List<Alerta> alerts;
  final Failure? failure;

  const AlertsState({
    this.isLoading = false,
    this.alerts = const [],
    this.failure,
  });

  int get unreadCount => alerts.where((a) => !a.leida).length;

  List<Alerta> get sorted => [...alerts]..sort((a, b) {
        if (a.severidad == SeveridadAlerta.critical &&
            !a.leida &&
            !(b.severidad == SeveridadAlerta.critical && !b.leida)) {
          return -1;
        }
        if (b.severidad == SeveridadAlerta.critical &&
            !b.leida &&
            !(a.severidad == SeveridadAlerta.critical && !a.leida)) {
          return 1;
        }
        return b.fechaCreacion.compareTo(a.fechaCreacion);
      });

  AlertsState copyWith({
    bool? isLoading,
    List<Alerta>? alerts,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      AlertsState(
        isLoading: isLoading ?? this.isLoading,
        alerts: alerts ?? this.alerts,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

class AlertsViewModel extends ChangeNotifier {
  final AlertsRepository _repository;
  final GetAlertsUseCase _getAlertsUC;
  final MarkAlertAsReadUseCase _markAsReadUC;
  final MarkAllAsReadUseCase _markAllAsReadUC;

  StreamSubscription<Alerta>? _subscription;

  AlertsState _state = const AlertsState();
  AlertsState get state => _state;

  AlertsViewModel({
    required this._repository,
    required this._getAlertsUC,
    required this._markAsReadUC,
    required this._markAllAsReadUC,
  });

  void _update(AlertsState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> loadAlerts() async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _getAlertsUC(const NoParams());
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (alerts) => _update(_state.copyWith(isLoading: false, alerts: alerts)),
    );
  }

  Future<void> markAsRead(int id) async {
    final result = await _markAsReadUC(id);
    result.fold(
      (f) => _update(_state.copyWith(failure: f)),
      (_) {
        final updated =
            _state.alerts.map((a) => a.id == id ? a.marcarLeida() : a).toList();
        _update(_state.copyWith(alerts: updated));
      },
    );
  }

  Future<void> markAllAsRead() async {
    final result = await _markAllAsReadUC(const NoParams());
    result.fold(
      (f) => _update(_state.copyWith(failure: f)),
      (_) {
        final updated = _state.alerts.map((a) => a.marcarLeida()).toList();
        _update(_state.copyWith(alerts: updated));
      },
    );
  }

  void startListening() {
    _subscription?.cancel();
    _subscription = _repository.watchNewAlerts().listen((alerta) {
      _update(_state.copyWith(alerts: [alerta, ..._state.alerts]));
    });
  }

  void stopListening() {
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
