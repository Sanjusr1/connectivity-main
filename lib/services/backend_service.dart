import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class BackendService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  String? _token;
  int? _currentSessionId;
  int? _currentDeviceId;
  bool _isInitializing = false;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<void> initSession() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      // 1. Create a dummy user token (mock implementation for simplicity)
      _token = "mock_token"; 
      
      // Wait, we need actual auth because of Depends(auth.get_current_user) in FastAPI.
      // Let's register a user and get a token.
      // Register user (ignore result if already exists)
      await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'flutter_app@example.com',
          'password': 'password123'
        }),
      );

      final tokenResp = await http.post(
        Uri.parse('$baseUrl/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'flutter_app@example.com',
          'password': 'password123'
        }),
      );
      
      if (tokenResp.statusCode == 200) {
        final tokenData = jsonDecode(tokenResp.body);
        _token = tokenData['access_token'];
      }

      // 2. Register Device (ignore result if already exists)
      await http.post(
        Uri.parse('$baseUrl/devices/'),
        headers: _headers,
        body: jsonEncode({
          'device_id': 'flutter_default_device',
          'name': 'Flutter App Device'
        }),
      );

      // Even if device already exists (400), we need its ID. Let's just fetch it.
      var devicesResp = await http.get(Uri.parse('$baseUrl/devices/'), headers: _headers);
      if (devicesResp.statusCode == 200) {
        final List devices = jsonDecode(devicesResp.body);
        if (devices.isNotEmpty) {
          _currentDeviceId = devices[0]['id'];
        }
      }

      if (_currentDeviceId != null) {
        // 3. Start Session
        final sessionResp = await http.post(
          Uri.parse('$baseUrl/sessions/'),
          headers: _headers,
          body: jsonEncode({
            'name': 'Auto Session ${DateTime.now().toIso8601String()}',
            'device_id': _currentDeviceId
          }),
        );
        if (sessionResp.statusCode == 200) {
          final sessionData = jsonDecode(sessionResp.body);
          _currentSessionId = sessionData['id'];
        }
      }
    } catch (e) {
      debugPrint('Failed to init session: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> sendSensorData(SensorData data) async {
    if (_currentSessionId == null) {
      await initSession();
    }
    
    if (_currentSessionId == null) {
      debugPrint('Still no session ID, skipping cloud upload.');
      return;
    }

    final url = Uri.parse('$baseUrl/sessions/$_currentSessionId/data');
    final Map<String, dynamic> bodyData = {
      'timestamp': data.timestamp.toIso8601String(),
    };
    
    bodyData['temperature'] = data.temperature;
    bodyData['humidity'] = data.humidity;
    bodyData['airflow'] = data.airflow;
    bodyData['pressure'] = data.pressure;
    bodyData['vibrationRms'] = data.vibrationRms;
    bodyData['microphoneLevel'] = data.microphoneLevel;
    bodyData['imuX'] = data.imuX;
    bodyData['imuY'] = data.imuY;
    bodyData['imuZ'] = data.imuZ;
    bodyData['rawFormat'] = data.rawFormat;
    if (data.rawPacket != null) bodyData['rawPacket'] = data.rawPacket;
    if (data.rawBytesBase64 != null) bodyData['rawBytesBase64'] = data.rawBytesBase64;

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(bodyData),
      );
      if (response.statusCode != 200) {
        debugPrint('Failed to send data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending data to backend: $e');
    }
  }
}

