import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/alerts/domain/entities/alerta.dart';

abstract interface class AlertsRepository {
  Future<Either<Failure, List<Alerta>>> getAlerts();
  Future<Either<Failure, void>> markAsRead(int id);
  Future<Either<Failure, void>> markAllAsRead();
  Stream<Alerta> watchNewAlerts();
}
