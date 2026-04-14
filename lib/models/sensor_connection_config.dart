enum SensorConnectionType { none, mock, wifi, usb }

class SensorConnectionConfig {
  const SensorConnectionConfig({
    required this.connectionType,
    this.wifiHost = '',
    this.wifiPort = 9000,
    this.usbBaudRate = 115200,
  });

  final SensorConnectionType connectionType;
  final String wifiHost;
  final int wifiPort;
  final int usbBaudRate;

  SensorConnectionConfig copyWith({
    SensorConnectionType? connectionType,
    String? wifiHost,
    int? wifiPort,
    int? usbBaudRate,
  }) {
    return SensorConnectionConfig(
      connectionType: connectionType ?? this.connectionType,
      wifiHost: wifiHost ?? this.wifiHost,
      wifiPort: wifiPort ?? this.wifiPort,
      usbBaudRate: usbBaudRate ?? this.usbBaudRate,
    );
  }

  String get connectionLabel {
    switch (connectionType) {
      case SensorConnectionType.none:
        return 'Not selected';
      case SensorConnectionType.mock:
        return 'Mock';
      case SensorConnectionType.wifi:
        return 'Wi-Fi';
      case SensorConnectionType.usb:
        return 'USB';
    }
  }
}
