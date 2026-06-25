import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/user_profile/domain/entities/vinculo.dart';
import 'package:medisync/features/user_profile/domain/repositories/link_repository.dart';

class RequestLinkUseCase implements UseCase<Vinculo, RequestLinkParams> {
  final LinkRepository _repository;

  RequestLinkUseCase(this._repository);

  @override
  Future<Either<Failure, Vinculo>> call(RequestLinkParams params) =>
      _repository.requestLink(params);
}
