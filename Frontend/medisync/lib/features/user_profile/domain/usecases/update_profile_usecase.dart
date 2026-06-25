import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/user_profile/domain/repositories/profile_repository.dart';

class UpdateProfileUseCase implements UseCase<Usuario, UpdateProfileParams> {
  final ProfileRepository _repository;

  UpdateProfileUseCase(this._repository);

  @override
  Future<Either<Failure, Usuario>> call(UpdateProfileParams params) =>
      _repository.updateProfile(params);
}
