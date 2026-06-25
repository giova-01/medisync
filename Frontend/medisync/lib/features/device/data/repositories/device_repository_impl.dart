import 'package:dio/dio.dart';
import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/network/api_client.dart';
import 'package:medisync/features/device/data/datasources/ble/ble_datasource.dart';
import 'package:medisync/features/device/data/datasources/local/device_local_datasource.dart';
import 'package:medisync/features/device/domain/entities/device.dart';
import 'package:medisync/features/device/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final BleDataSource _ble;
  final DeviceLocalDataSource _local;
  final ApiClient _api;

  DeviceRepositoryImpl({required this._ble, required this._local, required this._api});

  @override
  Future<Either<Failure, List<Device>>> scanDevices() async {
    try {
      final dtos = await _ble.scanDevices();
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on BleException catch (e) {
      return Left(BleFailure(e.message));
    } catch (_) {
      return const Left(BleFailure('Error al buscar dispositivos Bluetooth.'));
    }
  }

  @override
  Future<Either<Failure, Device>> connectDevice(String deviceId) async {
    try {
      final dto = await _ble.connectDevice(deviceId);
      await _local.saveDeviceId(deviceId);
      try {
        await _api.post<void>('/devices/link', body: {
          'mac_address': dto.id,
          'nombre': dto.name,
        });
      } on DioException catch (_) {
        // El vínculo BLE local ya quedó establecido; la sincronización con
        // el backend se reintentará en la próxima conexión o lectura.
      }
      return Right(dto.toEntity());
    } on BleException catch (e) {
      return Left(BleFailure(e.message));
    } catch (_) {
      return const Left(BleFailure('No se pudo conectar al dispositivo.'));
    }
  }

  @override
  Future<Either<Failure, void>> disconnectDevice() async {
    try {
      await _ble.disconnectDevice();
      await _local.clearDeviceId();
      try {
        await _api.delete<void>('/devices/me');
      } on DioException catch (_) {}
      return const Right(null);
    } on BleException catch (e) {
      return Left(BleFailure(e.message));
    } catch (_) {
      return const Left(BleFailure('Error al desconectar el dispositivo.'));
    }
  }

  @override
  Future<Either<Failure, Device?>> getConnectedDevice() async {
    try {
      final savedId = await _local.readDeviceId();
      if (savedId == null) return const Right(null);
      final dto = await _ble.connectDevice(savedId);
      return Right(dto.toEntity());
    } on BleException catch (_) {
      return const Right(null);
    } catch (_) {
      return const Right(null);
    }
  }
}
