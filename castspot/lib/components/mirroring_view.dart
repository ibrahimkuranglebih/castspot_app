import 'package:castspot/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../providers/connection_provider.dart';
import '../features/mirroring/mirroring_service.dart';

class MirroringView extends StatefulWidget {
  final String ipAddress;

  const MirroringView({Key? key, required this.ipAddress}) : super(key: key);

  @override
  _MirroringViewState createState() => _MirroringViewState();
}

class _MirroringViewState extends State<MirroringView> {
  late MirroringService _mirroringService;
  bool _isConnecting = false;
  Uint8List? _lastFrame;

  @override
  void initState() {
    super.initState();
    _mirroringService = MirroringService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMirroring());
  }

  //untuk memulai mirroring
  Future<void> _startMirroring() async {
    final connection = Provider.of<ConnectionProvider>(context, listen: false);
    
    setState(() => _isConnecting = true);
    try {
      await connection.connect(widget.ipAddress, mode: 'mirroring');
      await _mirroringService.startReceiving(widget.ipAddress);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: ${e.toString()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  //ketika stop mirroring
  Future<void> _stopMirroring() async {
    final connection = Provider.of<ConnectionProvider>(context, listen: false);
    await _mirroringService.stopReceiving();
    await connection.disconnect();
  }

  @override
  void dispose() {
    _mirroringService.stopReceiving();
    super.dispose();
  }

  //bagian di tampilan mirroring
  @override
  Widget build(BuildContext context) {
    final connection = Provider.of<ConnectionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Mirroring'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    border: Border.all(color: Colors.grey),
                  ),
                  child: connection.isConnected
                      ? StreamBuilder<Uint8List>(
                          stream: _mirroringService.frameStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }

                            if (snapshot.hasData) {
                              _lastFrame = snapshot.data!;
                            }

                            if (_lastFrame == null) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            return RotatedBox(
                              quarterTurns: 1,
                              child: Image.memory(
                                _lastFrame!,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,                             
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isConnecting)
                                const CircularProgressIndicator(),
                              Text(connection.connectionStatus),
                              if (connection.errorMessage.isNotEmpty)
                                Text(
                                  connection.errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
              //tombol stop mirroring
              if (connection.isConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                  child: SizedBox(
                    
                    width: double.infinity, 
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: GoogleFonts.inter().fontFamily),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            title: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold),),
                            content: const Text('Apakah Anda yakin ingin menghentikan mirroring?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Batal'),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: GoogleFonts.inter().fontFamily),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Ya'),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: GoogleFonts.inter().fontFamily),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _stopMirroring();
                        }
                      },
                      child: const Text('Stop Mirroring'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}