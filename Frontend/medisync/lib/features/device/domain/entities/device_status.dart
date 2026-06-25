enum DeviceStatus { disconnected, scanning, connecting, connected, error }

extension DeviceStatusX on DeviceStatus {
  String get label => switch (this) {
        DeviceStatus.disconnected => 'Desconectado',
        DeviceStatus.scanning => 'Buscando...',
        DeviceStatus.connecting => 'Conectando...',
        DeviceStatus.connected => 'Conectado',
        DeviceStatus.error => 'Error de conexión',
      };

  bool get isActive => this == DeviceStatus.connected;
  bool get isBusy =>
      this == DeviceStatus.scanning || this == DeviceStatus.connecting;
}
