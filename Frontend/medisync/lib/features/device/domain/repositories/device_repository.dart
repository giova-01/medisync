import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/device/domain/entities/device.dart';

abstract interface class DeviceRepository {
  Future<Either<Failure, List<Device>>> scanDevices();
  Future<Either<Failure, Device>> connectDevice(String deviceId);
  Future<Either<Failure, void>> disconnectDevice();
  Future<Either<Failure, Device?>> getConnectedDevice();
}
