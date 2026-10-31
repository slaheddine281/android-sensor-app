import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration constants for Supabase integration in StepQuest
class SupabaseConstants {
  SupabaseConstants._();

  /// Project Supabase URL
  static const String supabaseUrl = 'https://fiekedgvlhexhngfhjij.supabase.co';

  /// Project Supabase Anon Public Key
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpZWtlZGd2bGhleGhuZ2ZoamlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0NDk3OTcsImV4cCI6MjEwOTAyNTc5N30.s-s_wUIxN7ClWKhP_sxTWr8Rk0038-GejNtSCpUfadw';

  /// Table names
  static const String profilesTable = 'profiles';
  static const String notificationsTable = 'notifications';

  /// Checks if Supabase has been initialized in the current runtime environment
  static bool get isInitialized {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Safe accessor to the Supabase client singleton, or null if uninitialized (e.g. during unit tests)
  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
