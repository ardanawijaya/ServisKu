import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan JWT. Jika "Ingat Saya" tidak dicentang, token hanya di memori
/// (hilang saat aplikasi ditutup).
class TokenStorage {
  static const _key = 'auth_token';
  static String? _memory;

  static Future<String?> read() async {
    if (_memory != null) return _memory;
    final prefs = await SharedPreferences.getInstance();
    _memory = prefs.getString(_key);
    return _memory;
  }

  static Future<void> save(String token, {required bool remember}) async {
    _memory = token;
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString(_key, token);
    } else {
      await prefs.remove(_key);
    }
  }

  static Future<void> clear() async {
    _memory = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
