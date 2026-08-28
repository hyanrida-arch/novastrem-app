import 'package:flutter/material.dart';

/// NovaStream brand palette.
///
/// Deep, rich dark theme (matches the "living room TV" feel expected of a
/// premium IPTV client) with a violet/cyan neon accent pair used across
/// buttons, active nav states, rating badges and the logo mark.
abstract class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF7C4DFF); // NovaStream violet
  static const Color secondary = Color(0xFF00E5FF); // NovaStream cyan
  static const Color accent = Color(0xFFFF4081);

  // Surfaces
  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF171A20);
  static const Color surfaceElevated = Color(0xFF20242C);
  static const Color card = Color(0xFF1B1E25);

  // Text
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFFA0A0B2);
  static const Color textDisabled = Color(0xFF5A5A6B);

  // Status
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFC107);
  static const Color live = Color(0xFFFF1744);
  static const Color ratingGold = Color(0xFFFFC94D);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Bottom-fade used under hero banners / poster cards so overlaid text
  /// stays legible regardless of the artwork underneath.
  static const LinearGradient scrimBottom = LinearGradient(
    colors: [Colors.transparent, Color(0xE60F1115)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 8)),
  ];
}
