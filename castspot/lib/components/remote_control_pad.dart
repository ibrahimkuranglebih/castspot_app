import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';

class RemoteControlPad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connection = Provider.of<ConnectionProvider>(context);

    return Column(
      children: [
        Text("Remote Control", style: TextStyle(fontSize: 18)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton("↑", () {
              connection.sendMessage('{"type":"mouse_move","dy":-10}');
            }),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton("←", () {
              connection.sendMessage('{"type":"mouse_move","dx":-10}');
            }),
            _buildControlButton("↓", () {
              connection.sendMessage('{"type":"mouse_move","dy":10}');
            }),
            _buildControlButton("→", () {
              connection.sendMessage('{"type":"mouse_move","dx":10}');
            }),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            connection.sendMessage('{"type":"click"}');
          },
          child: Text("Klik"),
        ),
        if (!connection.isConnected)
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              connection.errorMessage.isNotEmpty 
                  ? connection.errorMessage 
                  : 'Not connected',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildControlButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(20),
        ),
      ),
    );
  }
}