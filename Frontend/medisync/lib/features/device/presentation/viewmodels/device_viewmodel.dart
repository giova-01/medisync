import 'package:flutter/foundation.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/core/usecases/use_case.dart';
import 'package:medisync/features/device/domain/entities/device.dart';
import 'package:medisync/features/device/domain/entities/device_status.dart';
import 'package:medisync/features/device/domain/usecases/connect_device_usecase.dart';
import 'package:medisync/features/device/domain/usecases/disconnect_device_usecase.dart';
import 'package:medisync/features/device/domain/usecases/get_connected_device_usecase.dart';
import 'package:medisync/features/device/domain/usecases/scan_devices_usecase.dart';

class DeviceState {
  final DeviceStatus status;
  final List<Device> availableDevices;
  final Device? connectedDevice;
  final Failure? failure;

  const DeviceState({
    this.status = DeviceStatus.disconnected,
    this.availableDevices = const [],
    this.connectedDevice,
    this.failure,
  });

  DeviceState copyWith({
    DeviceStatus? status,
    List<Device>? availableDevices,
    Device? connectedDevice,
    bool clearConnected = false,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      DeviceState(
        status: status ?? this.status,
        availableDevices: availableDevices ?? this.availableDevices,
        connectedDevice:
            clearConnected ? null : (connectedDevice ?? this.connectedDevice),
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

class DeviceViewModel extends ChangeNotifier {
  final ScanDevicesUseCase _scanUC;
  final ConnectDeviceUseCase _connectUC;
  final DisconnectDeviceUseCase _disconnectUC;
  final GetConnectedDeviceUseCase _getConnectedUC;

  DeviceState _state = const DeviceState();
  DeviceState get state => _state;

  DeviceViewModel({
    required this._scanUC,
    required this._connectUC,
    required this._disconnectUC,
    required this._getConnectedUC,
  });

  void _update(DeviceState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> checkConnectionStatus() async {
    final result = await _getConnectedUC(const NoParams());
    result.fold(
      (_) {},
      (device) {
        if (device != null) {
          _update(_state.copyWith(
              status: DeviceStatus.connected, connectedDevice: device));
        }
      },
    );
  }

  Future<void> scan() async {
    _update(_state.copyWith(
      status: DeviceStatus.scanning,
      availableDevices: const [],
      clearFailure: true,
    ));
    final result = await _scanUC(const NoParams());
    result.fold(
      (f) => _update(_state.copyWith(status: DeviceStatus.error, failure: f)),
      (devices) => _update(_state.copyWith(
        status: _state.connectedDevice != null
            ? DeviceStatus.connected
            : DeviceStatus.disconnected,
        availableDevices: devices,
      )),
    );
  }

  Future<void> connect(String deviceId) async {
    _update(_state.copyWith(
        status: DeviceStatus.connecting, clearFailure: true));
    final result = await _connectUC(deviceId);
    result.fold(
      (f) => _update(_state.copyWith(status: DeviceStatus.error, failure: f)),
      (device) => _update(_state.copyWith(
        status: DeviceStatus.connected,
        connectedDevice: device,
        availableDevices: const [],
      )),
    );
  }

  Future<void> disconnect() async {
    final result = await _disconnectUC(const NoParams());
    result.fold(
      (f) => _update(_state.copyWith(failure: f)),
      (_) => _update(_state.copyWith(
        status: DeviceStatus.disconnected,
        clearConnected: true,
        availableDevices: const [],
      )),
    );
  }

  void clearFailure() => _update(_state.copyWith(clearFailure: true));
}
