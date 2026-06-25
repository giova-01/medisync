import 'package:flutter/foundation.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/user_profile/domain/repositories/profile_repository.dart';
import 'package:medisync/features/user_profile/domain/usecases/get_profile_usecase.dart';
import 'package:medisync/features/user_profile/domain/usecases/update_profile_usecase.dart';

class ProfileState {
  final bool isLoading;
  final Usuario? user;
  final Failure? failure;
  final bool updateSuccess;

  const ProfileState({
    this.isLoading = false,
    this.user,
    this.failure,
    this.updateSuccess = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    Usuario? user,
    Failure? failure,
    bool clearFailure = false,
    bool? updateSuccess,
  }) =>
      ProfileState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        failure: clearFailure ? null : (failure ?? this.failure),
        updateSuccess: updateSuccess ?? this.updateSuccess,
      );
}

class ProfileViewModel extends ChangeNotifier {
  final GetProfileUseCase _getProfileUC;
  final UpdateProfileUseCase _updateUC;

  ProfileState _state = const ProfileState();
  ProfileState get state => _state;

  ProfileViewModel({
    required this._getProfileUC,
    required this._updateUC,
  });

  Future<void> loadProfile() async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _getProfileUC(const NoParams());
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (u) => _update(_state.copyWith(isLoading: false, user: u)),
    );
  }

  Future<void> updateProfile(UpdateProfileParams params) async {
    _update(_state.copyWith(isLoading: true, clearFailure: true, updateSuccess: false));
    final result = await _updateUC(params);
    result.fold(
      (f) => _update(_state.copyWith(isLoading: false, failure: f)),
      (u) => _update(
          _state.copyWith(isLoading: false, user: u, updateSuccess: true)),
    );
  }

  void clearFailure() => _update(_state.copyWith(clearFailure: true));

  void clearSuccess() => _update(_state.copyWith(updateSuccess: false));

  void _update(ProfileState s) {
    _state = s;
    notifyListeners();
  }
}
