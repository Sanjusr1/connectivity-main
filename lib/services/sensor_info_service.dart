import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/sensor_info.dart';

class SensorInfoService {
  Future<List<SensorInfo>> loadSensors() async {
    final rawJson = await rootBundle.loadString('assets/sensors.json');
    final decoded = jsonDecode(rawJson) as List<dynamic>;

    return decoded
        .map((item) => SensorInfo.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
