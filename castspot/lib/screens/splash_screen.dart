import 'package:flutter/material.dart';
import 'dart:async';
import 'main_navigation_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigasi otomatis setelah 3 detik
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainNavigationScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'images/splash/background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Konten
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'images/splash/logo.png',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 20),

                // Subjudul
                const Text(
                  'Koneksi Tanpa Batas, Layar di Genggaman',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F3F5B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),

                // Loader dari library
                const SpinKitFadingCube(
                  color: Color(0xFF1F3F5B),
                  size: 40.0,
                ),
                const SizedBox(height: 10),

                // Teks loading
                const Text(
                  'Sedang memuat...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F3F5B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
