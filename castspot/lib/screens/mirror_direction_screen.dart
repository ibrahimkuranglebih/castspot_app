import 'package:castspot/components/mirroring_view.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:permission_handler/permission_handler.dart';
import '../colors.dart';
import '../core/network_scanner.dart';


class MirrorDirectionScreen extends StatefulWidget {
  final VoidCallback? onTutorialComplete;
  final BuildContext? navContext;

  const MirrorDirectionScreen({
    Key? key,
    this.onTutorialComplete,
    this.navContext,
  }) : super(key: key);

  @override
  _MirrorDirectionScreenState createState() => _MirrorDirectionScreenState();
}

class _MirrorDirectionScreenState extends State<MirrorDirectionScreen> {
  List<TargetFocus> targets = [];
  final GlobalKey _mirrorPcToPhoneKey = GlobalKey();
  final GlobalKey _mirrorPhoneToPcKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownTutorial = prefs.getBool('mirror_tutorial_shown') ?? false;

    if (!hasShownTutorial) {
      showWelcomeDialog();
    }
  }

  //dialog awal pembukaan aplikasi
  void showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Selamat Datang di CastSpot!"),
        content: const Text("Tekan Lanjut untuk memulai panduan."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showTutorial();
            },
            child: const Text("Lanjut"),
          ),
        ],
      ),
    );
  }

  //scan dan navigasikan ke mirror
  void _scanAndNavigateToMirror(BuildContext context) async {
    final status = await Permission.location.request();

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Izin lokasi diperlukan untuk scan perangkat")),
      );
      return;
    }

    final devices = await NetworkScanner.scanMdnsDevices();

    if (devices.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20, 16, 20, 16),
          content: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Tidak Ada Perangkat PC Yang Tersambung !",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.start,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Pastikan PC Anda terhubung ke jaringan yang sama dengan perangkat ini.",
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, size: 24),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    //menampilkan dialog pilihan perangkat
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pilih Perangkat PC",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(height: 12,),
            Expanded(
              child: ListView.separated( 
                shrinkWrap: true, 
                itemCount: devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8), 
                itemBuilder: (_, index) {
                  final device = devices[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                    tileColor: const Color(0xFF205E8D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), 
                    ),
                    leading: const Icon(Icons.devices, color: Colors.white),
                    title: Text(
                      device.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    //ketika perangkat dipilih, maka akan menavigasikan ke mirroring view dengan menggunakan ip address dari perangkat yang dipilih
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.white,
                          title: Text('Konfirmasi Mirroring'),
                          content: Text('${device.name} meminta untuk melakukan mirror layar, lanjut?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(), 
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Batal', style: TextStyle(color: Colors.white),),
                              
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(); 
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MirroringView(ipAddress: device.ip),
                                  ),
                                );
                              },
                              child: Text('Ya', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );                      
                    },
                  );
                },
              ),)
          ],
        )
      ),
    );
  }

  //menampilkan tutorial 
  void showTutorial() async {
    targets.clear();

    targets.add(
      TargetFocus(
        identify: "MirrorPCtoPhone",
        keyTarget: _mirrorPcToPhoneKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Mirror PC to Phone",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                SizedBox(height: 10),
                Text(
                  "Gunakan fitur ini untuk mengendalikan PC dari perangkat mobile Anda.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "MirrorPhonetoPC",
        keyTarget: _mirrorPhoneToPcKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Mirror Phone to PC",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                SizedBox(height: 10),
                Text(
                  "Proyeksikan layar HP ke layar PC dengan mudah dan cepat.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final tutorial = TutorialCoachMark(
      targets: targets,
      skipWidget: const Text("Lewati", style: TextStyle(color: Colors.white)),
      paddingFocus: 10,
      opacityShadow: 0.8,
      colorShadow: Colors.black,
      onFinish: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('mirror_tutorial_shown', true);

        if (widget.onTutorialComplete != null) {
          widget.onTutorialComplete!();
        }

        if (widget.navContext != null) {
          Future.delayed(Duration(milliseconds: 300), () {
            TutorialCoachMark(
              targets: [
                TargetFocus(
                  identify: "MirrorNav",
                  keyTarget: GlobalObjectKey("mirrorNav"),
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
                TargetFocus(
                  identify: "RemoteNav",
                  keyTarget: GlobalObjectKey("remoteNav"),
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
                TargetFocus(
                  identify: "SettingsNav",
                  keyTarget: GlobalObjectKey("settingsNav"),
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
              ],
              skipWidget: const Text("Lewati", style: TextStyle(color: Colors.white)),
              paddingFocus: 10,
              opacityShadow: 0.8,
              colorShadow: Colors.black,
            ).show(context: widget.navContext!);
          });
        }
      },
    );

    tutorial.show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'CastSpot',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Pilih Jenis Mirroring',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildMirrorToPhoneOption(
                context,
                title: 'Mirror dari PC ke Ponsel',
                description: 'Kontrol PC Anda dari ponsel dengan mudah.',
                imageAsset: 'images/image_1.png',
                key: _mirrorPcToPhoneKey,
              ),
              const SizedBox(height: 16),
              _buildMirrorToPCOption(
                context,
                title: 'Mirror dari Ponsel ke PC',
                description: 'Anda dapat memproyeksikan layar ponsel ke PC.',
                imageAsset: 'images/image_1.png',
                key: _mirrorPhoneToPcKey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  //mirror dari pc ke ponsel
  Widget _buildMirrorToPhoneOption(
    BuildContext context, {
    required String title,
    required String description,
    required String imageAsset,
    required Key key,
  }) {
    return Card(
      key: key,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.asset(
              imageAsset,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(description,
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _scanAndNavigateToMirror(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Mirroring',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                    )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //mirror dari ponsel ke pc
  Widget _buildMirrorToPCOption(
    BuildContext context, {
    required String title,
    required String description,
    required String imageAsset,
    required Key key,
  }) {
    return Card(
      key: key,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.asset(
              imageAsset,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(description,
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _scanAndNavigateToMirror(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Mirroring',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                    )),
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
