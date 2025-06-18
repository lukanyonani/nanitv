// lib/utils/colors.dart
import 'package:flutter/material.dart';

/// 🎨 Centralized app color palette
class AppColors {
  /// Overall background behind everything
  static const Color background = Color.fromARGB(255, 13, 14, 17);

  /// Cards, panels & tab bar background
  static const Color surface = Color(0xFF121318);

  /// (A slightly lighter variant we saw behind the centered card)
  static const Color cardBackground = Color(0xFF0D1928);

  /// Semi-opaque black overlay (e.g. detail screen dimmer)
  static const Color overlay = Color(0x80000000);

  /// Electric cyan accent (buttons, focused borders, active tabs)
  static const Color accent = Color(0xFF00E5FF);

  /// Netflix signature red (for that logo and title)
  static const Color netflixRed = Color(0xFFE50914);

  /// Primary text (movie titles, headings)
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text (subtitles, hints, inactive tabs/icons)
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// Alias for inactive icons & tabs
  static const Color inactive = textSecondary;

  /// Alias for active icons & tabs
  static const Color active = accent;
}
