import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/supabase_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    publishableKey: SupabaseConstants.supabaseAnonKey,
  );

  // Restore session from URL if opened via recovery or magic link (Flutter Web)
  if (kIsWeb) {
    try {
      final url = Uri.base;
      final urlStr = url.toString();
      if (urlStr.contains('access_token') ||
          urlStr.contains('code=') ||
          urlStr.contains('type=recovery')) {
        await Supabase.instance.client.auth.getSessionFromUrl(url);
      }
    } catch (e) {
      debugPrint('main getSessionFromUrl error: $e');
    }
  }

  // Set system overlay style for clean status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const StepQuestApp());
}
