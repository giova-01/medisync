import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/device/domain/entities/device.dart';
import 'package:medisync/features/device/domain/repositories/device_repository.dart';

class ConnectDeviceUseCase implements UseCase<Device, String> {
  final DeviceRepository _repository;
  ConnectDeviceUseCase(this._repository);

  @override
  Future<Either<Failure, Device>> call(String params) =>
      _repository.connectDevice(params);
}
