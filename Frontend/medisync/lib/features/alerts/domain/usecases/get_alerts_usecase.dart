import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/alerts/domain/entities/alerta.dart';
import 'package:medisync/features/alerts/domain/repositories/alerts_repository.dart';

class GetAlertsUseCase implements UseCase<List<Alerta>, NoParams> {
  final AlertsRepository _repository;
  GetAlertsUseCase(this._repository);

  @override
  Future<Either<Failure, List<Alerta>>> call(NoParams params) =>
      _repository.getAlerts();
}
