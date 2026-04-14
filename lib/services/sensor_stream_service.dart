import '../models/sensor_connection_config.dart';
import '../models/sensor_data.dart';

abstract class SensorStreamService {
  Future<void> prepareConnection({
    required SensorConnectionConfig config,
  }) async {}

  Stream<SensorData> streamData({required SensorConnectionConfig config});

  Future<void> disconnect();
}
