import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}

/// Authenticates a user and returns the authenticated [Usuario].
class LoginUseCase implements UseCase<Usuario, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Either<Failure, Usuario>> call(LoginParams params) =>
      _repository.login(params.email, params.password);
}
