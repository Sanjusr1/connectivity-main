import 'dart:async';
import 'dart:math';

import '../models/sensor_connection_config.dart';
import '../models/sensor_data.dart';
import 'sensor_stream_service.dart';

class MockSensorStreamService implements SensorStreamService {
  final Random _random = Random();

  @override
  Future<void> prepareConnection({
    required SensorConnectionConfig config,
  }) async {}

  @override
  Stream<SensorData> streamData({
    required SensorConnectionConfig config,
    Duration interval = const Duration(seconds: 1),
  }) {
    return Stream.periodic(interval, (_) => _generateReading());
  }

  SensorData _generateReading() {
    final now = DateTime.now();
    final speechBurst = _random.nextDouble() > 0.68;

    return SensorData(
      timestamp: now,
      temperature: 24 + _random.nextDouble() * 5,
      humidity: 48 + _random.nextDouble() * 18,
      airflow: speechBurst
          ? 3.2 + _random.nextDouble() * 2.8
          : _random.nextDouble() * 2.2,
      pressure: 96 + _random.nextDouble() * 34,
      vibrationRms: speechBurst
          ? 0.55 + _random.nextDouble() * 0.4
          : 0.08 + _random.nextDouble() * 0.35,
      microphoneLevel: speechBurst
          ? 65 + _random.nextDouble() * 18
          : 35 + _random.nextDouble() * 15,
      imuX: -1 + _random.nextDouble() * 2,
      imuY: -1 + _random.nextDouble() * 2,
      imuZ: 0.65 + _random.nextDouble() * 0.7,
    );
  }

  @override
  Future<void> disconnect() async {}
}
