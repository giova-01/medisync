import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import '../repositories/auth_repository.dart';

/// Sends a password-reset e-mail to the given address.
class RecoverPasswordUseCase implements UseCase<void, String> {
  final AuthRepository _repository;

  RecoverPasswordUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(String email) =>
      _repository.recoverPassword(email);
}
