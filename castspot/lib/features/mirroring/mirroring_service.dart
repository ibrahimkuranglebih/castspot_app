import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class MirroringService {
  final StreamController<Uint8List> _controller = StreamController.broadcast();
  Stream<Uint8List> get frameStream => _controller.stream;
  http.Client? _client;
  bool _isRunning = false;

  //fungsi untuk menerima stream dari server
  Future<void> startReceiving(String ipAddress) async {
    if (_isRunning) return;
    _isRunning = true;
    _client = http.Client();
    final uri = Uri.parse('http://$ipAddress:5000/mirror');

    try {
      final request = http.Request('GET', uri);
      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        List<int> buffer = [];
        await for (var chunk in response.stream) {
          buffer.addAll(chunk);

          final startIndex = _findJPEGStart(buffer);
          final endIndex = _findJPEGEnd(buffer);

          if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            final jpegBytes = buffer.sublist(startIndex, endIndex + 2);
            _controller.add(Uint8List.fromList(jpegBytes));
            buffer = buffer.sublist(endIndex + 2);
          }
        }
      } else {
        throw Exception('Failed to connect to mirror stream');
      }
    } catch (e) {
      _controller.addError(e);
    }
  }

  Future<void> stopReceiving() async {
    _isRunning = false;
    _client?.close();
    await _controller.close();
  }

  int _findJPEGStart(List<int> bytes) {
    for (int i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8) return i;
    }
    return -1;
  }

  int _findJPEGEnd(List<int> bytes) {
    for (int i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == 0xD9) return i + 1;
    }
    return -1;
  }
}
