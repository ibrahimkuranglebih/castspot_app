import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final List<Map<String, String>> developers = [
    {'name': 'Ibrahim Mumtaz Samadikun', 'nim': '2307411028'},
    {'name': 'Alden Nafisa Hermawan', 'nim': ''},
    {'name': 'Anjuan Kaisar', 'nim': '2307411023'},
    {'name': 'Chia Wilsen', 'nim': '2307411005'},
    {'name': 'Rayner Aditya Radjasa', 'nim': '2307411024'},
    {'name': 'Dhanny Abdul Qodir', 'nim': '2307411012'},
  ];

  final Color primaryColor = const Color.fromRGBO(32, 94, 141, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setelan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CastSpot',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Versi Aplikasi: 1.2',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Pembuat Aplikasi:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tim Pengembang Kelompok 2',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: developers.length,
                itemBuilder: (context, index) {
                  final dev = developers[index];
                  return Card(
                    color: Colors.white,
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(
                          dev['name']![0],
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(dev['name'] ?? ''),
                      subtitle: Text(
                        dev['nim'] != null && dev['nim']!.isNotEmpty
                            ? 'NIM: ${dev['nim']}'
                            : 'NIM: -',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}