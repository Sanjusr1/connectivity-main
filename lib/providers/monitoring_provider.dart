import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sensor_connection_config.dart';
import '../models/sensor_data.dart';
import '../services/sensor_stream_service.dart';
import '../services/storage_service.dart';

class MonitoringProvider extends ChangeNotifier {
  MonitoringProvider({
    required SensorStreamService streamService,
    required StorageService storageService,
  }) : _streamService = streamService,
       _storageService = storageService;

  static const int framesPerSecond = 100;
  static const double speechAirflowThreshold = 3.0;
  static const int maxChartPoints = 30;
  static const List<String> defaultSensorIds = [
    'piezo_vibration',
    'mems_microphone',
    'airflow_sensor',
    'pressure_sensor',
    'imu_sensor',
    'temp_humidity',
  ];
  static const Map<String, String> sensorLabels = {
    'piezo_vibration': 'Vibration',
    'mems_microphone': 'Microphone',
    'airflow_sensor': 'Airflow',
    'pressure_sensor': 'Pressure',
    'imu_sensor': 'IMU',
    'temp_humidity': 'Temp & Humidity',
  };

  final SensorStreamService _streamService;
  final StorageService _storageService;

  StreamSubscription<SensorData>? _subscription;
  final List<SensorData> _history = [];
  final Set<String> _activeSensorIds = {...defaultSensorIds};
  final Map<String, int> _framesBySensor = {
    for (final sensorId in defaultSensorIds) sensorId: 0,
  };
  int _durationSeconds = 0;
  int _totalFrames = 0;
  bool _storeLocally = true;
  bool _storeInCloud = false;
  SensorConnectionConfig _connectionConfig = const SensorConnectionConfig(
    connectionType: SensorConnectionType.wifi,
    wifiPort: 9000,
  );
  String? _lastError;
  String _connectionState = 'Disconnected';

  SensorData? get latest => _history.isEmpty ? null : _history.last;
  List<SensorData> get history => List.unmodifiable(_history);
  List<SensorData> get recentReadings => _history.reversed.take(8).toList();
  Set<String> get activeSensorIds => Set.unmodifiable(_activeSensorIds);
  Map<String, int> get framesBySensor => Map.unmodifiable(_framesBySensor);
  bool get isMonitoring => _subscription != null;
  int get durationSeconds => _durationSeconds;
  int get totalFrames => _totalFrames;
  int get combinedSensorFrames =>
      _framesBySensor.values.fold(0, (total, frames) => total + frames);
  int get activeSensorCount => _activeSensorIds.length;
  int get samplingRate => framesPerSecond;
  bool get storeLocally => _storeLocally;
  bool get storeInCloud => _storeInCloud;
  bool get speechDetected => (latest?.airflow ?? 0) >= speechAirflowThreshold;
  SensorConnectionConfig get connectionConfig => _connectionConfig;
  String? get lastError => _lastError;
  String get connectionState => _connectionState;
  String get connectionSummary {
    switch (_connectionConfig.connectionType) {
      case SensorConnectionType.mock:
        return 'Mock generator';
      case SensorConnectionType.wifi:
        final host = _connectionConfig.wifiHost.trim();
        if (host.isEmpty) {
          return 'Wi-Fi sensor hub not configured';
        }
        return 'TCP ${_connectionConfig.wifiHost}:${_connectionConfig.wifiPort}';
      case SensorConnectionType.usb:
        return 'Android USB sensor hub';
    }
  }

  bool isSensorActive(String sensorId) => _activeSensorIds.contains(sensorId);

  int framesForSensor(String sensorId) => _framesBySensor[sensorId] ?? 0;

  Future<void> startMonitoring() async {
    if (isMonitoring) {
      return;
    }

    _lastError = null;
    _connectionState = 'Connecting...';
    notifyListeners();

    try {
      await _streamService.prepareConnection(config: _connectionConfig);
    } catch (error) {
      _connectionState = 'Error';
      _lastError = error.toString();
      notifyListeners();
      return;
    }

    _subscription = _streamService
        .streamData(config: _connectionConfig)
        .listen(
          _onReading,
          onError: _onStreamError,
          onDone: _onStreamDone,
          cancelOnError: true,
        );
    notifyListeners();
  }

  Future<void> stopMonitoring() async {
    await _subscription?.cancel();
    _subscription = null;
    await _streamService.disconnect();
    _connectionState = 'Disconnected';
    notifyListeners();
  }

  void resetSession() {
    _history.clear();
    _durationSeconds = 0;
    _totalFrames = 0;
    for (final sensorId in defaultSensorIds) {
      _framesBySensor[sensorId] = 0;
    }
    notifyListeners();
  }

  void setSensorActive(String sensorId, bool isActive) {
    if (isActive) {
      _activeSensorIds.add(sensorId);
    } else if (_activeSensorIds.length > 1) {
      _activeSensorIds.remove(sensorId);
    }
    notifyListeners();
  }

  void setStoreLocally(bool value) {
    _storeLocally = value;
    notifyListeners();
  }

  void setStoreInCloud(bool value) {
    _storeInCloud = value;
    notifyListeners();
  }

  void setConnectionType(SensorConnectionType value) {
    _connectionConfig = _connectionConfig.copyWith(connectionType: value);
    _lastError = null;
    if (!isMonitoring) {
      _connectionState = 'Disconnected';
    }
    notifyListeners();
  }

  void setWifiHost(String value) {
    _connectionConfig = _connectionConfig.copyWith(wifiHost: value.trim());
    _lastError = null;
    notifyListeners();
  }

  void setWifiPort(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return;
    }
    _connectionConfig = _connectionConfig.copyWith(wifiPort: parsed);
    _lastError = null;
    notifyListeners();
  }

  void setUsbBaudRate(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return;
    }
    _connectionConfig = _connectionConfig.copyWith(usbBaudRate: parsed);
    _lastError = null;
    notifyListeners();
  }

  Future<void> _onReading(SensorData data) async {
    _connectionState = 'Streaming';
    _history.add(data);
    if (_history.length > maxChartPoints) {
      _history.removeAt(0);
    }

    _durationSeconds += 1;
    _totalFrames += framesPerSecond;
    for (final sensorId in _activeSensorIds) {
      _framesBySensor[sensorId] =
          (_framesBySensor[sensorId] ?? 0) + framesPerSecond;
    }

    if (_storeLocally) {
      await _storageService.saveLocal(data);
    }
    if (_storeInCloud) {
      await _storageService.saveCloud(data);
    }

    notifyListeners();
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    _subscription = null;
    _connectionState = 'Error';
    _lastError = error.toString();
    notifyListeners();
  }

  void _onStreamDone() {
    _subscription = null;
    if (_connectionState != 'Error') {
      _connectionState = 'Disconnected';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _streamService.disconnect();
    super.dispose();
  }
}
