import 'package:web_socket_channel/web_socket_channel.dart';

class RemoteClient {
  late WebSocketChannel _channel;

  void connect(String ip) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://$ip:8080'),
    );
  }

  void sendCommand(String command) {
    _channel.sink.add(command);
  }

  Stream get stream => _channel.stream;

  void disconnect() {
    _channel.sink.close();
  }
}