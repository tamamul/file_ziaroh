import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const UploadScreen(),
      GalleryScreen(
        myFilesOnly: true,
        myNama: PrefService.nama,
      ),
      const GalleryScreen(myFilesOnly: false),
    ]);
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
          // Refresh "Riwayat Saya" saat tab dipilih supaya nama terupdate
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
