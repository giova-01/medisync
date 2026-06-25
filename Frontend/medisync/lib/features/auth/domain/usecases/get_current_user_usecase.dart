import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

/// Returns the locally cached [Usuario], or null when no session is active.
/// Used by [AuthViewModel.checkAuthStatus] on app start.
class GetCurrentUserUseCase implements UseCase<Usuario?, NoParams> {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  @override
  Future<Either<Failure, Usuario?>> call(NoParams params) =>
      _repository.currentUser();
}
