import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../colors.dart';
import 'mirror_direction_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final GlobalKey _mirrorNavKey = GlobalObjectKey("mirrorNav");
  final GlobalKey _remoteNavKey = GlobalObjectKey("remoteNav");
  final GlobalKey _settingsNavKey = GlobalObjectKey("settingsNav");

  late List<Widget> _screens;

  TutorialCoachMark? _navTutorial;

  bool _tutorialShown = false; // Flag untuk cek tutorial sudah pernah ditampilkan

  @override
  void initState() {
    super.initState();
    _screens = [
      MirrorDirectionScreen(
        onTutorialComplete: () {
          // optional tambahan, bisa tetap kosong
        },
        navContext: context,
      ),
      HomeScreen(),
      SettingsScreen(),
    ];
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool shown = prefs.getBool('tutorialShown') ?? false;

    setState(() {
      _tutorialShown = shown;
    });
  }

  Future<void> _setTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorialShown', true);
    setState(() {
      _tutorialShown = true;
    });
  }

  void showNavTutorial() {
    List<TargetFocus> targets = [];

    targets.add(
      TargetFocus(
        identify: "MirrorNav",
        keyTarget: _mirrorNavKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Tab Mirror: Untuk memilih fitur mirror screen.",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "RemoteNav",
        keyTarget: _remoteNavKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Tab Remote: Mengendalikan perangkat jarak jauh.",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "SettingsNav",
        keyTarget: _settingsNavKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Tab Settings: Pengaturan aplikasi.",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    _navTutorial = TutorialCoachMark(
      targets: targets,
      skipWidget: const Text("Lewati", style: TextStyle(color: Colors.white)),
      paddingFocus: 10,
      opacityShadow: 0.8,
      colorShadow: Colors.black,
      onFinish: () {
        print("Tutorial nav selesai");
      },
    );

    _navTutorial!.show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.primary,
          selectedItemColor: Colors.white,
          unselectedItemColor: AppColors.textWhiteSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.screenshot_monitor_outlined, key: _mirrorNavKey),
              activeIcon: Icon(Icons.screenshot_monitor, key: _mirrorNavKey),
              label: 'Mirror',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cast_outlined, key: _remoteNavKey),
              activeIcon: Icon(Icons.cast, key: _remoteNavKey),
              label: 'Remote',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, key: _settingsNavKey),
              activeIcon: Icon(Icons.settings, key: _settingsNavKey),
              label: 'Setelan',
            ),
          ],
        ),
      ),
    );
  }
}
