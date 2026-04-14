import 'package:hive_flutter/hive_flutter.dart';

import '../models/sensor_data.dart';
import 'backend_service.dart';
class StorageService {
  static const String _boxName = 'sensor_data_entries';
  Box<Map>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
  }

  Future<void> saveLocal(SensorData data) async {
    await _box?.add(data.toMap());
  }

  final BackendService _backendService = BackendService();

  Future<void> saveCloud(SensorData data) async {
    await _backendService.sendSensorData(data);
  }

  Future<List<SensorData>> loadLocalEntries() async {
    final values = _box?.values ?? const Iterable<Map>.empty();
    return values
        .map((entry) => SensorData.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Future<void> clearLocalEntries() async {
    await _box?.clear();
  }
}
