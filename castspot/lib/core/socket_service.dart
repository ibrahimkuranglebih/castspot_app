import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

class SocketService {
  static const int port = 5000;
  Socket? _socket;
  bool _isConnected = false;

  Future<void> connect(String ip) async {
    try {
      _socket = await Socket.connect(ip, port, timeout: Duration(seconds: 5));
      _socket?.setOption(SocketOption.tcpNoDelay, true);
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      throw Exception('Connection failed: $e');
    }
  }

  Stream<Uint8List> get stream async* {
    if (_socket == null) throw Exception('Not connected');
    
    final buffer = BytesBuilder();
    var expectedLength = 0;
    var receivedLength = 0;

    await for (final data in _socket!) {
      buffer.add(data);
      receivedLength += data.length;

      // First 4 bytes contain frame length
      if (expectedLength == 0 && buffer.length >= 4) {
        final bytes = buffer.takeBytes();
        expectedLength = ByteData.sublistView(bytes, 0, 4)
            .getUint32(0, Endian.big);
        buffer.add(bytes.sublist(4)); // put back the rest after the length header
      }

      // When we have complete frame
      if (expectedLength > 0 && receivedLength >= expectedLength) {
        final allBytes = buffer.takeBytes();
        final frameData = allBytes.sublist(0, expectedLength);
        final remaining = allBytes.sublist(expectedLength);
        buffer.add(remaining);
        yield Uint8List.fromList(frameData);
        
        // Reset for next frame
        expectedLength = 0;
        receivedLength = 0;
      }
    }
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _isConnected = false;
  }

  bool get isConnected => _isConnected;

  void send(message) {}
}