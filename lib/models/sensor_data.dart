class SensorData {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double airflow;
  final double pressure;
  final double vibrationRms;
  final double microphoneLevel;
  final double imuX;
  final double imuY;
  final double imuZ;
  final Map<String, dynamic> rawTransportMap;
  final String? rawPacket;
  final String? rawBytesBase64;
  final String rawFormat;

  SensorData({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.airflow,
    required this.pressure,
    required this.vibrationRms,
    required this.microphoneLevel,
    required this.imuX,
    required this.imuY,
    required this.imuZ,
    Map<String, dynamic>? rawTransportMap,
    this.rawPacket,
    this.rawBytesBase64,
    this.rawFormat = 'json',
  }) : rawTransportMap = Map.unmodifiable(rawTransportMap ?? const {});

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'airflow': airflow,
      'pressure': pressure,
      'vibrationRms': vibrationRms,
      'microphoneLevel': microphoneLevel,
      'imuX': imuX,
      'imuY': imuY,
      'imuZ': imuZ,
      'rawTransportMap': Map<String, dynamic>.from(rawTransportMap),
      if (rawPacket != null) 'rawPacket': rawPacket,
      if (rawBytesBase64 != null) 'rawBytesBase64': rawBytesBase64,
      'rawFormat': rawFormat,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      timestamp: DateTime.parse(map['timestamp'] as String),
      temperature: (map['temperature'] as num).toDouble(),
      humidity: (map['humidity'] as num).toDouble(),
      airflow: (map['airflow'] as num).toDouble(),
      pressure: (map['pressure'] as num).toDouble(),
      vibrationRms: (map['vibrationRms'] as num).toDouble(),
      microphoneLevel: ((map['microphoneLevel'] ?? 0) as num).toDouble(),
      imuX: (map['imuX'] as num).toDouble(),
      imuY: (map['imuY'] as num).toDouble(),
      imuZ: (map['imuZ'] as num).toDouble(),
      rawTransportMap: _readRawTransportMap(map),
      rawPacket: map['rawPacket'] as String?,
      rawBytesBase64: map['rawBytesBase64'] as String?,
      rawFormat: map['rawFormat'] as String? ?? 'json',
    );
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData.fromMap(json);
  }

  factory SensorData.fromTransportMap(
    Map<String, dynamic> map, {
    String? rawPacket,
    String? rawBytesBase64,
  }) {
    double readDouble(List<String> keys, {double fallback = 0}) {
      for (final key in keys) {
        final value = map[key];
        if (value is num) {
          return value.toDouble();
        }
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            return parsed;
          }
        }
      }
      return fallback;
    }

    DateTime readTimestamp() {
      final rawTimestamp = map['timestamp'] ?? map['ts'];
      if (rawTimestamp is String && rawTimestamp.isNotEmpty) {
        final parsed = DateTime.tryParse(rawTimestamp);
        if (parsed != null) {
          return parsed;
        }
      }
      if (rawTimestamp is num) {
        final epoch = rawTimestamp.toInt();
        return epoch > 9999999999
            ? DateTime.fromMillisecondsSinceEpoch(epoch)
            : DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
      }
      return DateTime.now();
    }

    return SensorData(
      timestamp: readTimestamp(),
      temperature: readDouble(['temperature', 'temp', 'temp_c']),
      humidity: readDouble(['humidity', 'humidity_percent', 'rh']),
      airflow: readDouble(['airflow', 'airflow_mps', 'flow']),
      pressure: readDouble(['pressure', 'pressure_pa']),
      vibrationRms: readDouble(['vibrationRms', 'vibration_rms', 'piezo_rms']),
      microphoneLevel: readDouble([
        'microphoneLevel',
        'microphone_level',
        'mic_db',
        'mic_level',
      ]),
      imuX: readDouble(['imuX', 'imu_x', 'accel_x', 'ax']),
      imuY: readDouble(['imuY', 'imu_y', 'accel_y', 'ay']),
      imuZ: readDouble(['imuZ', 'imu_z', 'accel_z', 'az']),
      rawTransportMap: map,
      rawPacket: rawPacket,
      rawBytesBase64: rawBytesBase64,
      rawFormat: 'json',
    );
  }

  factory SensorData.fromRawPacket({
    required Map<String, dynamic> rawTransportMap,
    required String rawFormat,
    String? rawPacket,
    String? rawBytesBase64,
  }) {
    return SensorData(
      timestamp: DateTime.now(),
      temperature: 0,
      humidity: 0,
      airflow: 0,
      pressure: 0,
      vibrationRms: 0,
      microphoneLevel: 0,
      imuX: 0,
      imuY: 0,
      imuZ: 0,
      rawTransportMap: rawTransportMap,
      rawPacket: rawPacket,
      rawBytesBase64: rawBytesBase64,
      rawFormat: rawFormat,
    );
  }

  static Map<String, dynamic> _readRawTransportMap(Map<String, dynamic> map) {
    final rawMap = map['rawTransportMap'];
    if (rawMap is Map) {
      return Map<String, dynamic>.from(rawMap);
    }
    return Map<String, dynamic>.from(map)
      ..remove('rawPacket')
      ..remove('rawBytesBase64')
      ..remove('rawFormat');
  }
}
