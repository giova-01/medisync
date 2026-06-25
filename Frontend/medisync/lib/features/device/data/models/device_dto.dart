import 'package:medisync/features/device/domain/entities/device.dart';

class DeviceDto {
  final String id;
  final String name;
  final int rssi;
  final bool isConnected;

  const DeviceDto({
    required this.id,
    required this.name,
    required this.rssi,
    this.isConnected = false,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) => DeviceDto(
        id: json['id'] as String,
        name: json['name'] as String,
        rssi: json['rssi'] as int,
        isConnected: json['is_connected'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rssi': rssi,
        'is_connected': isConnected,
      };

  Device toEntity() => Device(
        id: id,
        name: name,
        rssi: rssi,
        isConnected: isConnected,
      );
}
