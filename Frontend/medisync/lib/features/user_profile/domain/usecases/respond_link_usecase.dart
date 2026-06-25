import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/user_profile/domain/entities/vinculo.dart';
import 'package:medisync/features/user_profile/domain/repositories/link_repository.dart';

class RespondLinkUseCase implements UseCase<Vinculo, RespondLinkParams> {
  final LinkRepository _repository;

  RespondLinkUseCase(this._repository);

  @override
  Future<Either<Failure, Vinculo>> call(RespondLinkParams params) =>
      _repository.respondLink(params);
}
