import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConfig {
  /// Bisa di-override: flutter run --dart-define=API_URL=http://192.168.1.5:3000/api
  static String get baseUrl {
    const env = String.fromEnvironment('API_URL');
    if (env.isNotEmpty) return env;
    if (kIsWeb) return 'http://localhost:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api'; // emulator Android
    }
    return 'http://localhost:3000/api';
  }
}

class AppColors {
  static const primary = Color(0xFF2563EB);
  static const navy = Color(0xFF0F1F4D);
  static const orange = Color(0xFFF97316);
  static const orangeSoft = Color(0xFFFFEDE0);
  static const blueSoft = Color(0xFFE8EEFF);
  static const bg = Color(0xFFF8FAFC);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const danger = Color(0xFFDC2626);
}

class AppAssets {
  static const logoOnboarding = 'assets/images/logo_onboarding.png';
  static const logoHeader = 'assets/images/logo_header.png';
}
