import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/sensor_data.dart';
import 'backend_service.dart';
import 'exported_file.dart';
import 'local_data_exporter.dart';

enum LocalExportFormat { json, csv }

class LocalDataExportResult {
  const LocalDataExportResult({
    required this.file,
    required this.entryCount,
    required this.format,
  });

  final ExportedFile file;
  final int entryCount;
  final LocalExportFormat format;
}

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

  Future<LocalDataExportResult> exportLocalEntries(
    LocalExportFormat format,
  ) async {
    final entries = await loadLocalEntries();
    final timestamp = _fileTimestamp(DateTime.now());
    final extension = format == LocalExportFormat.json ? 'json' : 'csv';
    final fileName = 'sensor_data_$timestamp.$extension';
    final contents = switch (format) {
      LocalExportFormat.json => _toJson(entries),
      LocalExportFormat.csv => _toCsv(entries),
    };
    final mimeType = switch (format) {
      LocalExportFormat.json => 'application/json',
      LocalExportFormat.csv => 'text/csv',
    };

    final file = await exportTextFile(
      fileName: fileName,
      contents: contents,
      mimeType: mimeType,
    );

    return LocalDataExportResult(
      file: file,
      entryCount: entries.length,
      format: format,
    );
  }

  Future<void> clearLocalEntries() async {
    await _box?.clear();
  }

  String _toJson(List<SensorData> entries) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(entries.map((entry) => entry.toMap()).toList());
  }

  String _toCsv(List<SensorData> entries) {
    const headers = [
      'timestamp',
      'temperature',
      'humidity',
      'airflow',
      'pressure',
      'vibrationRms',
      'microphoneLevel',
      'imuX',
      'imuY',
      'imuZ',
      'rawFormat',
      'rawPacket',
      'rawBytesBase64',
      'rawTransportMap',
    ];

    final rows = [
      headers,
      for (final entry in entries)
        [
          entry.timestamp.toIso8601String(),
          entry.temperature,
          entry.humidity,
          entry.airflow,
          entry.pressure,
          entry.vibrationRms,
          entry.microphoneLevel,
          entry.imuX,
          entry.imuY,
          entry.imuZ,
          entry.rawFormat,
          entry.rawPacket ?? '',
          entry.rawBytesBase64 ?? '',
          jsonEncode(entry.rawTransportMap),
        ],
    ];

    return rows
        .map((row) => row.map((value) => _csvCell(value.toString())).join(','))
        .join('\n');
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r')) {
      return '"$escaped"';
    }
    return escaped;
  }

  String _fileTimestamp(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    final date = [
      time.year.toString(),
      twoDigits(time.month),
      twoDigits(time.day),
    ].join('');
    final clock = [
      twoDigits(time.hour),
      twoDigits(time.minute),
      twoDigits(time.second),
    ].join('');

    return '${date}_$clock';
  }
}
