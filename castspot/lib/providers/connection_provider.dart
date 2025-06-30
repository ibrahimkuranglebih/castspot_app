import 'package:flutter/material.dart';
import '../core/socket_service.dart';

class ConnectionProvider extends ChangeNotifier {
  SocketService? _socket;
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';
  String _errorMessage = '';
  String _mode = ''; // 'mirroring' atau 'remote'

  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  String get errorMessage => _errorMessage;
  String get mode => _mode;
  SocketService? get socket => _socket;

  get ipAddress => null;

  Future<void> connect(String ip, {required String mode}) async {
    try {
      _mode = mode;
      _connectionStatus = 'Connecting...';
      _errorMessage = '';
      notifyListeners();
      
      _socket = SocketService();
      await _socket?.connect(ip);
      await Future.delayed(Duration(milliseconds: 1)); // Simulate connection

      _isConnected = true;
      _connectionStatus = 'Connected';
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _connectionStatus = 'Disconnected';
      _errorMessage = 'Failed to connect: ${e.toString()}';
      Future.microtask(() => notifyListeners());
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _socket?.disconnect();
    } finally {
      _isConnected = false;
      _connectionStatus = 'Disconnected';
      _mode = '';
      notifyListeners();
    }
  }

  void sendMessage(dynamic message) {
    if (_isConnected && _socket != null) {
      _socket!.send(message);
    }
  }
}