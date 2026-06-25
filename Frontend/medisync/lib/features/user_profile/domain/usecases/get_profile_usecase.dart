import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/user_profile/domain/repositories/profile_repository.dart';

class GetProfileUseCase implements UseCase<Usuario, NoParams> {
  final ProfileRepository _repository;

  GetProfileUseCase(this._repository);

  @override
  Future<Either<Failure, Usuario>> call(NoParams params) =>
      _repository.getProfile();
}
