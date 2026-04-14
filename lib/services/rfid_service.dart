import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class RFIDService {
  static final RFIDService _instance = RFIDService._internal();
  factory RFIDService() => _instance;
  RFIDService._internal();

  WebSocketChannel? _channel;
  StreamController<String> _uidStreamController =
      StreamController<String>.broadcast();
  Stream<String> get uidStream => _uidStreamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  String? _currentDeviceIp;

  // Connect ke ESP32 via WebSocket
  Future<bool> connectToESP32(String ipAddress) async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$ipAddress:81'),
      );

      _channel!.stream.listen((message) {
        _handleIncomingMessage(message);
      }, onError: (error) {
        print('WebSocket error: $error');
        _isConnected = false;
      }, onDone: () {
        print('WebSocket disconnected');
        _isConnected = false;
      });

      _isConnected = true;
      _currentDeviceIp = ipAddress;
      return true;
    } catch (e) {
      print('Connection failed: $e');
      _isConnected = false;
      return false;
    }
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] == 'rfid' && data['uid'] != null) {
        _uidStreamController.add(data['uid']);
      } else if (data['type'] == 'fingerprint' && data['id'] != null) {
        _uidStreamController.add('FP_${data['id']}');
      } else if (data['type'] == 'both') {
        // Jika kedua sensor membaca bersamaan
        if (data['uid'] != null) {
          _uidStreamController.add(data['uid']);
        }
        if (data['fingerprint_id'] != null) {
          _uidStreamController.add('FP_${data['fingerprint_id']}');
        }
      }
    } catch (e) {
      // If not JSON, treat as plain UID
      _uidStreamController.add(message.toString());
    }
  }

  // Kirim konfirmasi ke ESP32
  void sendConfirmation(bool success, String uid, String userName) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode({
        'type': 'confirm',
        'uid': uid,
        'status': success ? 'approved' : 'rejected',
        'name': userName,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  // Kirim perintah ke ESP32 (misal: reset, get status, dll)
  void sendCommand(String command) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(command);
    }
  }

  // Disconnect
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  // Cek koneksi via HTTP
  Future<bool> checkConnection(String ipAddress) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/status'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
