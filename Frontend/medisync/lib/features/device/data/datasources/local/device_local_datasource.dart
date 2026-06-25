import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class DeviceLocalDataSource {
  Future<String?> readDeviceId();
  Future<void> saveDeviceId(String deviceId);
  Future<void> clearDeviceId();
}

class DeviceLocalDataSourceImpl implements DeviceLocalDataSource {
  static const _key = 'ble_device_id';
  final FlutterSecureStorage _storage;

  const DeviceLocalDataSourceImpl(this._storage);

  @override
  Future<String?> readDeviceId() => _storage.read(key: _key);

  @override
  Future<void> saveDeviceId(String deviceId) =>
      _storage.write(key: _key, value: deviceId);

  @override
  Future<void> clearDeviceId() => _storage.delete(key: _key);
}
