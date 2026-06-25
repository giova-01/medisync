import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/device/domain/entities/device.dart';
import 'package:medisync/features/device/domain/repositories/device_repository.dart';

class GetConnectedDeviceUseCase implements UseCase<Device?, NoParams> {
  final DeviceRepository _repository;
  GetConnectedDeviceUseCase(this._repository);

  @override
  Future<Either<Failure, Device?>> call(NoParams params) =>
      _repository.getConnectedDevice();
}
