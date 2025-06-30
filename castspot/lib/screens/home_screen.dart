import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/mirroring_view.dart';
import '../components/remote_control_pad.dart';
import '../core/network_scanner.dart';
import '../providers/connection_provider.dart';
import '../auth/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connection = Provider.of<ConnectionProvider>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Mirror & Remote")),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tombol Scan Jaringan
              ElevatedButton(
                onPressed: () async {
                  var status = await Permission.location.request();

                  if (status.isGranted) {
                    final devices = await NetworkScanner.scanMdnsDevices();
                    _showDeviceList(context, devices.map((d) => d.ip).toList());
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Izin lokasi diperlukan untuk scan jaringan')),
                    );
                  }
                },
                child: Text("Scan Perangkat"),
              ),

              SizedBox(height: 20),

              // Mirroring Section
              if (connection.isConnected) 
                MirroringView(ipAddress: connection.ipAddress),

              SizedBox(height: 20),

              // Remote Control Section
              if (auth.user != null && connection.isConnected)
                RemoteControlPad(),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeviceList(BuildContext context, List<String> ipList) {
    if (ipList.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Tidak ditemukan perangkat"),
          content: Text("Pastikan perangkat lain aktif dan berada dalam jaringan yang sama."),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: ipList.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(ipList[i]),
          onTap: () {
            Provider.of<ConnectionProvider>(context, listen: false)
                .connect(ipList[i], mode: 'client');
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
