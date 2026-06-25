import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/device/domain/entities/device.dart';
import 'package:medisync/features/device/domain/repositories/device_repository.dart';

class ScanDevicesUseCase implements UseCase<List<Device>, NoParams> {
  final DeviceRepository _repository;
  ScanDevicesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Device>>> call(NoParams params) =>
      _repository.scanDevices();
}
