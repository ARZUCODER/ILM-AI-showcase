import 'package:flutter/material.dart';

/// Apple Liquid Glass palette – deep dark base with vibrant accents.
class LiqColors {
  // Base surfaces
  static const Color bgDark = Color(0xFF0A0A0F);
  static const Color bgDeep = Color(0xFF050507);
  static const Color surface = Color(0xFF15151C);
  static const Color surfaceElevated = Color(0xFF1C1C24);

  // Glass overlay tints
  static const Color glassFill = Color(0x1AFFFFFF); // 10% white
  static const Color glassFillStrong = Color(0x33FFFFFF); // 20% white
  static const Color glassStroke = Color(0x26FFFFFF); // 15% white
  static const Color glassStrokeStrong = Color(0x40FFFFFF); // 25% white

  // Brand accents – emerald + mint glow
  static const Color accent = Color(0xFF34C759);
  static const Color accentSoft = Color(0xFF6EE7B7);
  static const Color accentDeep = Color(0xFF059669);
  static const Color accentGreen = accent; // legacy alias

  // Atmospheric gradient colors (used in backgrounds)
  static const Color auroraGreen = Color(0xFF10B981);
  static const Color auroraTeal = Color(0xFF0EA5E9);
  static const Color auroraViolet = Color(0xFF7C3AED);
  static const Color auroraPink = Color(0xFFEC4899);
  static const Color auroraAmber = Color(0xFFF59E0B);

  // Text
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xB3FAFAFA); // 70%
  static const Color textTertiary = Color(0x80FAFAFA); // 50%
  static const Color textMuted = Color(0x59FAFAFA); // 35%

  // Status
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);

  // Bubble colors
  static const Color bubbleUser = Color(0xFF34C759);
  static const Color bubbleAi = Color(0x1FFFFFFF);

  // Legacy aliases
  static const Color bgLight = bgDark;
  static const Color glassWhite = glassFill;
  static const Color glassDark = Color(0x4D000000);
  static const Color textPrimaryLight = textPrimary;
  static const Color textPrimaryDark = textPrimary;
}
