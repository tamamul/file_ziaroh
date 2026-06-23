import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'constants.dart';
import 'services/pref_service.dart';
import 'screens/upload_screen.dart';
import 'screens/gallery_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefService.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FileZiarahApp());
}

class FileZiarahApp extends StatelessWidget {
  const FileZiarahApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppConstants.appName,
    theme: AppTheme.theme,
    debugShowCheckedModeBanner: false,
    home: const MainScreen(),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;
  final _uploadKey = GlobalKey<UploadScreenState>();

  // Screens
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      UploadScreen(key: _uploadKey),
      GalleryScreen(myFilesOnly: true, myNama: PrefService.nama),
      const GalleryScreen(myFilesOnly: false),
    ];

    // Terima file saat app sudah buka (dari share WA dll)
    ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      if (files.isNotEmpty) _handleSharedFiles(files);
    });

    // Terima file saat app pertama kali dibuka via share
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      if (files.isNotEmpty) _handleSharedFiles(files);
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> shared) {
    final files = shared
        .where((f) => f.path.isNotEmpty)
        .map((f) => File(f.path))
        .where((f) => f.existsSync())
        .toList();

    if (files.isEmpty) return;

    // Pindah ke tab Upload
    setState(() => _tab = 0);

    // Tambah file ke UploadScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uploadKey.currentState?.addSharedFiles(files);
    });

    // Reset intent supaya tidak diproses ulang
    ReceiveSharingIntent.instance.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          Text(AppConstants.appName,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          Text(AppConstants.appSubtitle,
            style: const TextStyle(color: AppTheme.gold, fontSize: 10)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
            decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [Colors.transparent, AppTheme.gold, Colors.transparent]))),
        ),
      ),
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) {
          if (i == 1) {
            _screens[1] = GalleryScreen(myFilesOnly: true, myNama: PrefService.nama);
          }
          setState(() => _tab = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Riwayat Saya'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Galeri Tim'),
        ],
      ),
    );
  }
}
