import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/alerts/domain/repositories/alerts_repository.dart';

class MarkAllAsReadUseCase implements UseCase<void, NoParams> {
  final AlertsRepository _repository;
  MarkAllAsReadUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      _repository.markAllAsRead();
}
