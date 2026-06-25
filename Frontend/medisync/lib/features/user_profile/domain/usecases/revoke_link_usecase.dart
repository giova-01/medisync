import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/user_profile/domain/repositories/link_repository.dart';

class RevokeLinkUseCase implements UseCase<void, int> {
  final LinkRepository _repository;

  RevokeLinkUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(int vinculoId) =>
      _repository.revokeLink(vinculoId);
}
