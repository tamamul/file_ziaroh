import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class PrefService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String get nama => _prefs?.getString(AppConstants.keyNama) ?? '';
  static String get divisi => _prefs?.getString(AppConstants.keyDivisi) ?? '';

  static Future<void> saveNama(String v) async => _prefs?.setString(AppConstants.keyNama, v);
  static Future<void> saveDivisi(String v) async => _prefs?.setString(AppConstants.keyDivisi, v);

  static bool get hasIdentity => nama.isNotEmpty;
}
