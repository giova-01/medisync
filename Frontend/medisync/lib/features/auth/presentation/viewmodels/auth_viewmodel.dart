import 'package:flutter/foundation.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/auth/domain/repositories/auth_repository.dart';
import 'package:medisync/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:medisync/features/auth/domain/usecases/login_usecase.dart';
import 'package:medisync/features/auth/domain/usecases/logout_usecase.dart';
import 'package:medisync/features/auth/domain/usecases/recover_password_usecase.dart';
import 'package:medisync/features/auth/domain/usecases/register_usecase.dart';

// ---------------------------------------------------------------------------
// State (immutable)
// ---------------------------------------------------------------------------

class AuthState {
  final bool isLoading;
  final Usuario? user;
  final Failure? failure;
  final bool isPasswordRecoverySent;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.failure,
    this.isPasswordRecoverySent = false,
  });

  AuthState copyWith({
    bool? isLoading,
    Usuario? user,
    bool clearUser = false,
    Failure? failure,
    bool clearFailure = false,
    bool? isPasswordRecoverySent,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: clearUser ? null : (user ?? this.user),
        failure: clearFailure ? null : (failure ?? this.failure),
        isPasswordRecoverySent:
            isPasswordRecoverySent ?? this.isPasswordRecoverySent,
      );
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class AuthViewModel extends ChangeNotifier {
  final LoginUseCase _loginUC;
  final RegisterUseCase _registerUC;
  final LogoutUseCase _logoutUC;
  final RecoverPasswordUseCase _recoverPasswordUC;
  final GetCurrentUserUseCase _currentUserUC;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  AuthViewModel({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required RecoverPasswordUseCase recoverPasswordUseCase,
    required GetCurrentUserUseCase currentUserUseCase,
  })  : _loginUC = loginUseCase,
        _registerUC = registerUseCase,
        _logoutUC = logoutUseCase,
        _recoverPasswordUC = recoverPasswordUseCase,
        _currentUserUC = currentUserUseCase;

  // Called once in main() before runApp — reads cached user from secure storage.
  Future<void> checkAuthStatus() async {
    final result = await _currentUserUC(const NoParams());
    result.fold(
      (_) => _state = const AuthState(),
      (user) => _state = AuthState(user: user),
    );
    // No notifyListeners here: the widget tree hasn't mounted yet.
  }

  Future<void> login(String email, String password) async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _loginUC(LoginParams(email: email, password: password));
    result.fold(
      (failure) => _update(_state.copyWith(isLoading: false, failure: failure)),
      (user) => _update(_state.copyWith(isLoading: false, user: user)),
    );
  }

  Future<void> register(RegisterParams params) async {
    _update(_state.copyWith(isLoading: true, clearFailure: true));
    final result = await _registerUC(params);
    result.fold(
      (failure) => _update(_state.copyWith(isLoading: false, failure: failure)),
      (user) => _update(_state.copyWith(isLoading: false, user: user)),
    );
  }

  Future<void> logout() async {
    _update(_state.copyWith(isLoading: true));
    final result = await _logoutUC(const NoParams());
    result.fold(
      (failure) => _update(_state.copyWith(isLoading: false, failure: failure)),
      (_) => _update(const AuthState()),
    );
  }

  Future<void> recoverPassword(String email) async {
    _update(_state.copyWith(isLoading: true, clearFailure: true, isPasswordRecoverySent: false));
    final result = await _recoverPasswordUC(email);
    result.fold(
      (failure) => _update(_state.copyWith(isLoading: false, failure: failure)),
      (_) => _update(_state.copyWith(isLoading: false, isPasswordRecoverySent: true)),
    );
  }

  void clearFailure() => _update(_state.copyWith(clearFailure: true));

  void _update(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}
