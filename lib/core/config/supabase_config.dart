import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static late final String supabaseUrl;
  static late final String supabaseAnonKey;
  static bool isConfigured = false;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Warning: .env file not found or failed to load: $e");
    }

    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 
        const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    if (supabaseUrl.isNotEmpty && 
        supabaseAnonKey.isNotEmpty && 
        !supabaseUrl.contains('your-project-id')) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: supabaseAnonKey,
        );
        isConfigured = true;
      } catch (e) {
        debugPrint("Error initializing Supabase: $e");
      }
    } else {
      debugPrint("Supabase credentials not configured in .env");
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}

