import 'package:flutter/foundation.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/user_profile/domain/entities/vinculo.dart';
import 'package:medisync/features/user_profile/domain/repositories/link_repository.dart';
import 'package:medisync/features/user_profile/domain/usecases/list_links_usecase.dart';
import 'package:medisync/features/user_profile/domain/usecases/request_link_usecase.dart';
import 'package:medisync/features/user_profile/domain/usecases/respond_link_usecase.dart';
import 'package:medisync/features/user_profile/domain/usecases/revoke_link_usecase.dart';

class LinksState {
  final bool isLoading;
  final List<Vinculo> vinculos;
  final Failure? failure;
  final bool requestSuccess;

  const LinksState({
    this.isLoading = false,
    this.vinculos = const [],
    this.failure,
    this.requestSuccess = false,
  });

  LinksState copyWith({
    bool? isLoading,
    List<Vinculo>? vinculos,
    Failure? failure,
    bool clearFailure = false,
    bool? requestSuccess,
  }) =>
      LinksState(
        isLoading: isLoading ?? this.isLoading,
        vinculos: vinculos ?? this.vinculos,
        failure: clearFailure ? null : (failure ?? this.failure),
        requestSuccess: requestSuccess ?? this.requestSuccess,
      );
}

class LinksViewModel extends ChangeNotifier {
  final RequestLinkUseCase _requestUC;
  final RespondLinkUseCase _respondUC;
  final ListLinksUseCase _listUC;
  final RevokeLinkUseCase _revokeUC;

  LinksState _state = const LinksState();
  LinksState get state => _state;

  LinksViewModel({
    required this._requestUC,
    required this._respondUC,
    required this._listUC,
    required this._revokeUC,
  });

  Future<void> loadLinks() async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _listUC(const NoParams());
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (v) => _update(_state.copyWith(isLoading: false, vinculos: v)),
    );
  }

  Future<void> requestLink(String targetEmail, TipoVinculo rol) async {
    _update(_state.copyWith(isLoading: true, clearFailure: true, requestSuccess: false));
    final result = await _requestUC(
        RequestLinkParams(targetEmail: targetEmail, rol: rol));
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (v) {
        final updated = [..._state.vinculos, v];
        _update(_state.copyWith(
            isLoading: false, vinculos: updated, requestSuccess: true));
      },
    );
  }

  Future<void> acceptLink(int id) async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _respondUC(RespondLinkParams(vinculoId: id, aceptar: true));
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (v) => _update(_state.copyWith(
          isLoading: false,
          vinculos: _replaceVinculo(_state.vinculos, v))),
    );
  }

  Future<void> rejectLink(int id) async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _respondUC(RespondLinkParams(vinculoId: id, aceptar: false));
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (v) => _update(_state.copyWith(
          isLoading: false,
          vinculos: _replaceVinculo(_state.vinculos, v))),
    );
  }

  Future<void> revokeLink(int id) async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _revokeUC(id);
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (_) {
        final updated = _state.vinculos
            .map((v) => v.id == id
                ? Vinculo(
                    id: v.id,
                    idPaciente: v.idPaciente,
                    usuarioVinculado: v.usuarioVinculado,
                    tipoVinculo: v.tipoVinculo,
                    estado: EstadoVinculo.revocado,
                  )
                : v)
            .toList();
        _update(_state.copyWith(isLoading: false, vinculos: updated));
      },
    );
  }

  void clearFailure() => _update(_state.copyWith(clearFailure: true));

  void clearRequestSuccess() => _update(_state.copyWith(requestSuccess: false));

  List<Vinculo> _replaceVinculo(List<Vinculo> list, Vinculo updated) =>
      list.map((v) => v.id == updated.id ? updated : v).toList();

  void _update(LinksState s) {
    _state = s;
    notifyListeners();
  }
}
