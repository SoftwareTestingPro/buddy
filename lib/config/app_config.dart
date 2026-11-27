import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // In case .env file is missing or in test mode, fallback gracefully
    }
  }

  static String get appName => dotenv.env['APP_NAME'] ?? 'Buddy';
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Google OAuth Client ID configured at application level
  static String get googleClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
      '606517458068-ae9phm4df75auitujf788saaqhotqt29.apps.googleusercontent.com';

  static String get googleClientSecret => dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';

  static bool get isMockFallback => (dotenv.env['ENABLE_MOCK_FALLBACK'] ?? 'false') == 'true';
}
