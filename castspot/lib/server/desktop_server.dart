import 'dart:io';
import 'dart:convert';

class DesktopServer {
  late HttpServer _server;
  final Function(String)? onMessage;
  final Function(WebSocket)? onClientConnected;

  DesktopServer({this.onMessage, this.onClientConnected});

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    print('Server running on port 8080');

    await for (var request in _server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        onClientConnected?.call(socket);

        socket.listen((data) {
          onMessage?.call(data.toString());
        });
      }
    }
  }

  void stop() {
    _server.close();
  }
}