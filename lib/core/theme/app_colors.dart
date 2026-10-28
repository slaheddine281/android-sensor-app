import 'package:flutter/material.dart';

/// Centralized color palette for StepQuest according to the UI/UX mockup
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF3B82F6);       // Vibrant Blue
  static const Color primaryDark = Color(0xFF2563EB);   // Deep Blue
  static const Color primaryLight = Color(0xFF60A5FA);  // Light Blue
  static const Color primarySoft = Color(0xFFEFF6FF);   // Very soft blue background

  // Secondary & Accents
  static const Color secondary = Color(0xFF10B981);     // Emerald Green (Success, Active)
  static const Color secondarySoft = Color(0xFFECFDF5); // Soft green
  static const Color tertiary = Color(0xFFF59E0B);      // Amber Orange (Warning, Attention)
  static const Color tertiarySoft = Color(0xFFFFFBEB);  // Soft amber
  
  // Destructive / Error
  static const Color error = Color(0xFFEF4444);         // Red (Error, Delete, Suspended)
  static const Color errorSoft = Color(0xFFFEF2F2);     // Soft red

  // Navy Dark backgrounds (Admin & Splash & Biometric)
  static const Color navyDark = Color(0xFF0F172A);      // Deep Slate / Almost Black
  static const Color navyCard = Color(0xFF1E293B);      // Dark card surface
  static const Color navyHeader = Color(0xFF0F2A47);    // StepQuest Deep Navy Blue
  static const Color navySurface = Color(0xFF172554);   // Dark Navy surface
  static const Color navyGlow = Color(0xFF1D4ED8);      // Navy neon glow

  // Light surfaces
  static const Color background = Color(0xFFF1F5F9);    // Main light background
  static const Color backgroundLight = Color(0xFFF8FAFC);// Secondary light background
  static const Color card = Color(0xFFFFFFFF);          // Card white surface
  static const Color divider = Color(0xFFE2E8F0);       // Light border & divider
  static const Color border = Color(0xFFCBD5E1);        // Input border

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);   // Main dark text
  static const Color textSecondary = Color(0xFF64748B); // Slate neutral text
  static const Color textMuted = Color(0xFF94A3B8);     // Muted grey text
  static const Color textWhite = Color(0xFFFFFFFF);     // White text
  static const Color textWhite70 = Color(0xB3FFFFFF);   // White with opacity
}

