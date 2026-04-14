import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/sensor_connection_config.dart';
import '../models/sensor_data.dart';
import 'sensor_stream_service.dart';

class LiveSensorStreamService implements SensorStreamService {
  static const MethodChannel _usbControlChannel = MethodChannel(
    'connectivity_sensor_app/usb_control',
  );
  static const EventChannel _usbEventChannel = EventChannel(
    'connectivity_sensor_app/usb_stream',
  );

  Socket? _wifiSocket;
  StreamSubscription<dynamic>? _usbEventSubscription;

  @override
  Future<void> prepareConnection({
    required SensorConnectionConfig config,
  }) async {}

  @override
  Stream<SensorData> streamData({required SensorConnectionConfig config}) {
    switch (config.connectionType) {
      case SensorConnectionType.mock:
        return _buildMockStream();
      case SensorConnectionType.wifi:
        return _buildWifiStream(config);
      case SensorConnectionType.usb:
        return _buildUsbStream();
    }
  }

  Stream<SensorData> _buildMockStream() {
    final random = Random();
    return Stream.periodic(
      const Duration(seconds: 1),
      (_) => SensorData(
        timestamp: DateTime.now(),
        temperature: 24 + random.nextDouble() * 5,
        humidity: 48 + random.nextDouble() * 18,
        airflow: random.nextDouble() > 0.68
            ? 3.2 + random.nextDouble() * 2.8
            : random.nextDouble() * 2.2,
        pressure: 96 + random.nextDouble() * 34,
        vibrationRms: random.nextDouble() > 0.68
            ? 0.55 + random.nextDouble() * 0.4
            : 0.08 + random.nextDouble() * 0.35,
        microphoneLevel: 42 + random.nextDouble() * 28,
        imuX: -1 + random.nextDouble() * 2,
        imuY: -1 + random.nextDouble() * 2,
        imuZ: 0.65 + random.nextDouble() * 0.7,
      ),
    );
  }

  Stream<SensorData> _buildWifiStream(SensorConnectionConfig config) async* {
    if (config.wifiHost.trim().isEmpty) {
      throw const SensorConnectionException(
        'Enter the Wi-Fi sensor hub host or IP address.',
      );
    }

    await disconnect();

    try {
      final socket = await Socket.connect(
        config.wifiHost.trim(),
        config.wifiPort,
      );
      _wifiSocket = socket;
      yield* _splitPackets(socket.cast<List<int>>()).map(_decodePacketBytes);
    } on SocketException catch (error) {
      throw SensorConnectionException(
        'Wi-Fi connection failed: ${error.message}.',
      );
    } on HandshakeException catch (error) {
      throw SensorConnectionException(
        'Wi-Fi stream handshake failed: ${error.message}.',
      );
    }
  }

  Stream<SensorData> _buildUsbStream() {
    if (!Platform.isAndroid) {
      throw const SensorConnectionException(
        'USB collection is currently implemented for Android only.',
      );
    }

    late StreamController<SensorData> controller;
    controller = StreamController<SensorData>(
      onListen: () async {
        try {
          _usbEventSubscription = _usbEventChannel
              .receiveBroadcastStream()
              .listen((dynamic event) {
                try {
                  controller.add(_decodePacket(event));
                } catch (error) {
                  controller.addError(error);
                }
              }, onError: controller.addError);

          await _usbControlChannel.invokeMethod<String>('startUsbStream');
        } on PlatformException catch (error) {
          controller.addError(
            SensorConnectionException(
              error.message ?? 'Unable to start USB collection.',
            ),
          );
        }
      },
      onCancel: () async {
        await _usbEventSubscription?.cancel();
        _usbEventSubscription = null;
        try {
          await _usbControlChannel.invokeMethod<String>('stopUsbStream');
        } on PlatformException {
          // Ignore stop failures during teardown.
        }
      },
    );
    return controller.stream;
  }

  SensorData _decodePacket(dynamic rawPacket) {
    if (rawPacket is Map) {
      return SensorData.fromTransportMap(Map<String, dynamic>.from(rawPacket));
    }
    if (rawPacket is String) {
      return _decodePacketLine(rawPacket);
    }
    if (rawPacket is Uint8List) {
      return _decodePacketBytes(rawPacket);
    }
    if (rawPacket is List<int>) {
      return _decodePacketBytes(rawPacket);
    }
    throw const SensorConnectionException(
      'Unsupported packet format from sensor stream.',
    );
  }

  SensorData _decodePacketLine(String line) {
    return _decodePacketLineWithMetadata(line);
  }

  SensorData _decodePacketLineWithMetadata(
    String line, {
    String? rawBytesBase64,
    Map<String, dynamic>? transportMetadata,
  }) {
    final trimmedLine = line.trimRight();
    try {
      final decoded = jsonDecode(trimmedLine);
      if (decoded is Map<String, dynamic>) {
        return SensorData.fromTransportMap(
          {...?transportMetadata, ...decoded},
          rawPacket: line,
          rawBytesBase64: rawBytesBase64,
        );
      }
      return SensorData.fromRawPacket(
        rawTransportMap: {
          ...?transportMetadata,
          'raw_format': 'json_non_object',
          'raw_json': decoded,
        },
        rawFormat: 'json_non_object',
        rawPacket: line,
        rawBytesBase64: rawBytesBase64,
      );
    } on FormatException {
      return SensorData.fromRawPacket(
        rawTransportMap: {
          ...?transportMetadata,
          'raw_format': 'text',
          'raw_text': line,
        },
        rawFormat: 'text',
        rawPacket: line,
        rawBytesBase64: rawBytesBase64,
      );
    }
  }

  SensorData _decodePacketBytes(List<int> packetBytes) {
    final encodedPacket = base64Encode(packetBytes);
    String rawText;
    try {
      rawText = utf8.decode(packetBytes, allowMalformed: false);
    } on FormatException {
      return _buildRawBinaryPacket(packetBytes, encodedPacket: encodedPacket);
    }

    final line = rawText.endsWith('\r')
        ? rawText.substring(0, rawText.length - 1)
        : rawText;
    return _decodePacketLineWithMetadata(
      line,
      rawBytesBase64: encodedPacket,
      transportMetadata: {'raw_byte_count': packetBytes.length},
    );
  }

  SensorData _buildRawBinaryPacket(
    List<int> packetBytes, {
    String? encodedPacket,
  }) {
    final rawBase64 = encodedPacket ?? base64Encode(packetBytes);
    return SensorData.fromRawPacket(
      rawTransportMap: {
        'raw_format': 'binary',
        'raw_bytes_base64': rawBase64,
        'raw_byte_count': packetBytes.length,
      },
      rawFormat: 'binary',
      rawBytesBase64: rawBase64,
    );
  }

  Stream<List<int>> _splitPackets(Stream<List<int>> byteStream) async* {
    final buffer = <int>[];
    await for (final chunk in byteStream) {
      for (final byte in chunk) {
        if (byte == 10) {
          if (buffer.isNotEmpty) {
            yield List<int>.from(buffer);
            buffer.clear();
          }
        } else {
          buffer.add(byte);
        }
      }
    }

    if (buffer.isNotEmpty) {
      yield List<int>.from(buffer);
    }
  }

  @override
  Future<void> disconnect() async {
    await _usbEventSubscription?.cancel();
    _usbEventSubscription = null;

    try {
      await _usbControlChannel.invokeMethod<String>('stopUsbStream');
    } on PlatformException {
      // No-op when USB is not active.
    }

    await _wifiSocket?.close();
    _wifiSocket = null;
  }
}

class SensorConnectionException implements Exception {
  const SensorConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
