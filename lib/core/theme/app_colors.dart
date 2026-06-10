import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary gradient - Purple/Blue
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryIndigo = Color(0xFF4F46E5);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryBlue],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
  );

  // Dark theme colors
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkElevated = Color(0xFF1E2A45);
  static const Color darkBorder = Color(0xFF2A2A4A);
  static const Color darkDivider = Color(0xFF252545);

  // Light theme colors
  static const Color lightBackground = Color(0xFFF8F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF0F2FF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFEEF2FF);

  // Text colors
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Download status colors
  static const Color downloading = Color(0xFF3B82F6);
  static const Color paused = Color(0xFFF59E0B);
  static const Color completed = Color(0xFF10B981);
  static const Color failed = Color(0xFFEF4444);
  static const Color pending = Color(0xFF6366F1);

  // Platform colors
  static const Color youtubeRed = Color(0xFFFF0000);
  static const Color tiktokPink = Color(0xFFFF0050);
  static const Color instagramPurple = Color(0xFFE1306C);
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color twitterBlue = Color(0xFF1DA1F2);
  static const Color vimeoBlue = Color(0xFF1AB7EA);

  // Glassmorphism colors
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassDark = Color(0x1A000000);
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderDark = Color(0x1AFFFFFF);

  // Premium/Gold colors
  static const Color gold = Color(0xFFFFBF00);
  static const Color goldLight = Color(0xFFFFF3CC);
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFBF00), Color(0xFFFF6B00)],
  );

  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color shimmerBase = Color(0xFF2A2A4A);
  static const Color shimmerHighlight = Color(0xFF3A3A5A);

  // ── Convenience aliases used across the UI ─────────────────────────────────
  /// Alias for [primaryPurple]
  static const Color primaryColor = primaryPurple;

  /// Alias for [error]
  static const Color errorColor = error;

  /// Alias for [success]
  static const Color successColor = success;

  /// Alias for [warning]
  static const Color warningColor = warning;

  /// Alias for [info]
  static const Color infoColor = info;

  /// Mid-tone secondary text color (neutral grey)
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Generic surface/card background (mid-dark)
  static const Color surfaceColor = darkCard;
}
