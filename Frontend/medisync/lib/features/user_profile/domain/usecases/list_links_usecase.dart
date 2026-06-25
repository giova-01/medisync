import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/user_profile/domain/entities/vinculo.dart';
import 'package:medisync/features/user_profile/domain/repositories/link_repository.dart';

class ListLinksUseCase implements UseCase<List<Vinculo>, NoParams> {
  final LinkRepository _repository;

  ListLinksUseCase(this._repository);

  @override
  Future<Either<Failure, List<Vinculo>>> call(NoParams params) =>
      _repository.listLinks();
}
