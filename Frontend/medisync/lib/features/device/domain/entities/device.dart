class Device {
  final String id;
  final String name;
  final int rssi;
  final bool isConnected;

  const Device({
    required this.id,
    required this.name,
    required this.rssi,
    this.isConnected = false,
  });
}
