import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/alerts/domain/repositories/alerts_repository.dart';

class MarkAlertAsReadUseCase implements UseCase<void, int> {
  final AlertsRepository _repository;
  MarkAlertAsReadUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(int params) =>
      _repository.markAsRead(params);
}
