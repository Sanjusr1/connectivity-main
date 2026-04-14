import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'dart:typed_data';

import '../models/sensor_connection_config.dart';
import '../models/sensor_data.dart';
import 'sensor_stream_service.dart';

class LiveSensorStreamService implements SensorStreamService {
  JSObject? _serial;
  JSObject? _port;
  JSObject? _reader;
  bool _shouldRead = false;
  final List<int> _usbPacketBuffer = <int>[];
  Map<String, dynamic> _portMetadata = const {};

  @override
  Future<void> prepareConnection({
    required SensorConnectionConfig config,
  }) async {
    if (config.connectionType != SensorConnectionType.usb) {
      return;
    }

    final navigator = globalContext['navigator'] as JSObject?;
    final serial = navigator?['serial'] as JSObject?;
    if (serial == null) {
      throw const SensorConnectionException(
        'Web Serial API is unavailable in this browser. Use Chrome or Edge over HTTPS or localhost.',
      );
    }

    _serial = serial;
    final knownPorts = await (_serial!.callMethod<JSPromise<JSArray<JSAny?>>>(
      'getPorts'.toJS,
    ))!.toDart;
    final grantedPorts = knownPorts.toDart;

    if (grantedPorts.isNotEmpty) {
      _port = grantedPorts.first as JSObject;
    } else {
      _port = await (_serial!.callMethod<JSPromise<JSObject>>(
        'requestPort'.toJS,
      ))!.toDart;
    }

    if (_port == null) {
      throw const SensorConnectionException(
        'No USB serial device was selected.',
      );
    }

    _portMetadata = _readPortMetadata(_port!);
    final readable = _port!['readable'];
    if (readable == null) {
      await (_port!.callMethod<JSPromise<JSAny?>>(
        'open'.toJS,
        {
          'baudRate': config.usbBaudRate,
          'bufferSize': 65536,
          'dataBits': 8,
          'stopBits': 1,
          'parity': 'none',
          'flowControl': 'none',
        }.jsify(),
      ))!.toDart;
    }
  }

  @override
  Stream<SensorData> streamData({required SensorConnectionConfig config}) {
    switch (config.connectionType) {
      case SensorConnectionType.mock:
        return _buildMockStream();
      case SensorConnectionType.wifi:
        throw const SensorConnectionException(
          'Wi-Fi socket streaming is not available in the web build yet. Use USB serial or Mock mode in Chrome.',
        );
      case SensorConnectionType.usb:
        return _buildUsbStream(config);
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

  Stream<SensorData> _buildUsbStream(SensorConnectionConfig config) {
    late StreamController<SensorData> controller;
    controller = StreamController<SensorData>(
      onListen: () async {
        try {
          await prepareConnection(config: config);

          final readable = _port?['readable'] as JSObject?;
          if (readable == null) {
            throw const SensorConnectionException(
              'The selected USB serial device is not readable.',
            );
          }

          _shouldRead = true;
          _reader = readable.callMethod<JSObject>('getReader'.toJS);

          while (_shouldRead) {
            final chunkResult = await (_reader!.callMethod<JSPromise<JSObject>>(
              'read'.toJS,
            ))!.toDart;

            final isDone = (chunkResult['done'] as JSBoolean?)?.toDart ?? false;
            final value = chunkResult['value'];
            if (isDone) {
              break;
            }
            if (value == null) {
              continue;
            }

            final chunk = _toUint8List(value);
            for (final frame in _decodeUsbChunk(chunk)) {
              controller.add(frame);
            }
          }

          final trailingFrame = _flushTrailingUsbFrame();
          if (trailingFrame != null) {
            controller.add(trailingFrame);
          }
        } catch (error) {
          controller.addError(
            error is SensorConnectionException
                ? error
                : SensorConnectionException('USB serial read failed: $error'),
          );
        }
      },
      onCancel: disconnect,
    );
    return controller.stream;
  }

  List<SensorData> _decodeUsbChunk(Uint8List chunk) {
    final frames = <SensorData>[];
    for (final byte in chunk) {
      if (byte == 10) {
        if (_usbPacketBuffer.isNotEmpty) {
          frames.add(_decodePacketBytes(List<int>.from(_usbPacketBuffer)));
          _usbPacketBuffer.clear();
        }
      } else {
        _usbPacketBuffer.add(byte);
      }
    }
    return frames;
  }

  SensorData? _flushTrailingUsbFrame() {
    if (_usbPacketBuffer.isEmpty) {
      return null;
    }
    final frame = _decodePacketBytes(List<int>.from(_usbPacketBuffer));
    _usbPacketBuffer.clear();
    return frame;
  }

  Uint8List _toUint8List(JSAny value) {
    if (value.isA<JSUint8Array>()) {
      return (value as JSUint8Array).toDart;
    }
    final converted = value.dartify();
    if (converted is Uint8List) {
      return converted;
    }
    if (converted is List) {
      return Uint8List.fromList(
        converted.map((entry) => (entry as num).toInt()).toList(),
      );
    }
    throw const SensorConnectionException(
      'USB serial returned an unsupported byte buffer.',
    );
  }

  Map<String, dynamic> _readPortMetadata(JSObject port) {
    try {
      final info = port.callMethod<JSObject>('getInfo'.toJS);
      final parsed = info.dartify();
      if (parsed is Map) {
        return {
          'source': 'web_usb_serial',
          ...Map<String, dynamic>.from(parsed),
        };
      }
    } catch (_) {
      // Best effort only.
    }
    return const {'source': 'web_usb_serial'};
  }

  SensorData _decodePacketLine(String line, {required String rawBytesBase64}) {
    final trimmedLine = line.trimRight();
    try {
      final decoded = jsonDecode(trimmedLine);
      if (decoded is Map<String, dynamic>) {
        return SensorData.fromTransportMap(
          {..._portMetadata, ...decoded},
          rawPacket: line,
          rawBytesBase64: rawBytesBase64,
        );
      }
      return SensorData.fromRawPacket(
        rawTransportMap: {
          ..._portMetadata,
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
          ..._portMetadata,
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
      return SensorData.fromRawPacket(
        rawTransportMap: {
          ..._portMetadata,
          'raw_format': 'binary',
          'raw_bytes_base64': encodedPacket,
          'raw_byte_count': packetBytes.length,
        },
        rawFormat: 'binary',
        rawBytesBase64: encodedPacket,
      );
    }

    final line = rawText.endsWith('\r')
        ? rawText.substring(0, rawText.length - 1)
        : rawText;
    return _decodePacketLine(line, rawBytesBase64: encodedPacket);
  }

  @override
  Future<void> disconnect() async {
    _shouldRead = false;
    _usbPacketBuffer.clear();

    if (_reader != null) {
      try {
        await (_reader!.callMethod<JSPromise<JSAny?>>('cancel'.toJS))!.toDart;
      } catch (_) {
        // Ignore cancel failures during teardown.
      }
      try {
        _reader!.callMethod<JSAny?>('releaseLock'.toJS);
      } catch (_) {
        // Ignore release failures.
      }
      _reader = null;
    }

    if (_port != null) {
      try {
        await (_port!.callMethod<JSPromise<JSAny?>>('close'.toJS))!.toDart;
      } catch (_) {
        // Ignore close failures. The browser may already consider it closed.
      }
      _port = null;
    }
  }
}

class SensorConnectionException implements Exception {
  const SensorConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
