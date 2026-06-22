import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = 'https://chat.marsa9.com/dok-ziaroh';
  static const String uploadUrl = '$baseUrl/upload.php';
  static const String apiUrl = '$baseUrl/api.php';
  static const String appName = 'File Ziaroh';
  static const String appSubtitle = 'PP. Darul Musthofa';

  static const List<String> divisiList = ['Foto', 'Video', 'Maqom', 'Perjalanan'];

  // SharedPreferences keys
  static const String keyNama = 'user_nama';
  static const String keyDivisi = 'user_divisi';
}

class AppTheme {
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE8C97A);
  static const Color greenDark = Color(0xFF0D1F16);
  static const Color greenMid = Color(0xFF1A3A2A);
  static const Color greenRim = Color(0xFF3A7A52);
  static const Color greenCard = Color(0xFF111F17);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: greenDark,
    colorScheme: ColorScheme.dark(
      primary: gold,
      secondary: greenRim,
      surface: greenCard,
      background: greenDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A1A10),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: greenMid,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: greenRim),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: greenRim),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF5A8A6A)),
      hintStyle: const TextStyle(color: Color(0xFF5A8A6A)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: greenRim,
        foregroundColor: goldLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: greenMid,
      selectedColor: gold.withOpacity(0.3),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      side: const BorderSide(color: greenRim),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0A1A10),
      selectedItemColor: gold,
      unselectedItemColor: Color(0xFF5A8A6A),
      type: BottomNavigationBarType.fixed,
    ),
  );
}
