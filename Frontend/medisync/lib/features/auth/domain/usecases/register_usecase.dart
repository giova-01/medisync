import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

/// Registers a new user and returns the created [Usuario].
class RegisterUseCase implements UseCase<Usuario, RegisterParams> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Either<Failure, Usuario>> call(RegisterParams params) =>
      _repository.register(params);
}
