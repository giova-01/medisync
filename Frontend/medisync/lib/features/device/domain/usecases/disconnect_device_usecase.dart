import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/device/domain/repositories/device_repository.dart';

class DisconnectDeviceUseCase implements UseCase<void, NoParams> {
  final DeviceRepository _repository;
  DisconnectDeviceUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      _repository.disconnectDevice();
}
