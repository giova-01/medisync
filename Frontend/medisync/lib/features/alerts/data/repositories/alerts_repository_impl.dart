import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/alerts/data/datasources/notification_datasource.dart';
import 'package:medisync/features/alerts/domain/entities/alerta.dart';
import 'package:medisync/features/alerts/domain/repositories/alerts_repository.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  final NotificationDataSource _notificationDS;

  AlertsRepositoryImpl({required this._notificationDS});

  @override
  Future<Either<Failure, List<Alerta>>> getAlerts() async {
    try {
      final dtos = await _notificationDS.getAlerts();
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(NetworkFailure('No se pudieron cargar las alertas.'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int id) async {
    try {
      await _notificationDS.markAsRead(id);
      return const Right(null);
    } catch (_) {
      return const Left(
          NetworkFailure('No se pudo marcar la alerta como leída.'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await _notificationDS.markAllAsRead();
      return const Right(null);
    } catch (_) {
      return const Left(
          NetworkFailure('No se pudieron marcar las alertas como leídas.'));
    }
  }

  @override
  Stream<Alerta> watchNewAlerts() =>
      _notificationDS.watchNewAlerts().map((dto) => dto.toEntity());
}
