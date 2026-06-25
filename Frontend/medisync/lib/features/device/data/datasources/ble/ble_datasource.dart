import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/features/device/data/models/device_dto.dart';

abstract interface class BleDataSource {
  Future<List<DeviceDto>> scanDevices();
  Future<DeviceDto> connectDevice(String deviceId);
  Future<void> disconnectDevice();
}

class BleDataSourceMock implements BleDataSource {
  static const _devices = [
    DeviceDto(id: 'AA:BB:CC:DD:EE:FF', name: 'MediSync-ESP32', rssi: -62),
    DeviceDto(id: '11:22:33:44:55:66', name: 'MediSync-ESP32-2', rssi: -78),
  ];

  DeviceDto? _connected;

  @override
  Future<List<DeviceDto>> scanDevices() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    return List.unmodifiable(_devices);
  }

  @override
  Future<DeviceDto> connectDevice(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final device = _devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw const BleException('Dispositivo no encontrado.'),
    );
    _connected = DeviceDto(
      id: device.id,
      name: device.name,
      rssi: device.rssi,
      isConnected: true,
    );
    return _connected!;
  }

  @override
  Future<void> disconnectDevice() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _connected = null;
  }

  DeviceDto? get connectedDevice => _connected;
}
