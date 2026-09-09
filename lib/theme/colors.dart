import 'package:flutter/material.dart';

class CuteColors {
  // --- Premium Accent Palette ---
  // Vibrant but soft colors for accents, buttons, and glows
  static const Color primary = Color(0xFFFF8FB1);   // Vibrant Candy Pink
  static const Color secondary = Color(0xFFB19CD9); // Soft Lavender
  static const Color tertiary = Color(0xFFB2F2CC);   // Fresh Mint
  static const Color highlight = Color(0xFFFDEB71);  // Sunny Yellow

  // --- Surface & Glass Colors ---
  // Desaturated, translucent colors for glassmorphism
  static const Color surfaceLight = Color(0xCCFFFFFF); // 80% White
  static const Color surfaceDark = Color(0xCC1A1A1A);  // 80% Dark Grey
  static const Color glassBorderLight = Color(0x33FFFFFF); // Thin white reflection
  static const Color glassBorderDark = Color(0x33000000);  // Thin dark reflection

  // --- Text & Contrast ---
  static const Color darkText = Color(0xFF3D3D3D);
  static const Color lightText = Color(0xFF757575);
  static const Color pureWhite = Colors.white;
  static const Color pureBlack = Colors.black;

  // --- Dark Mode Foundation ---
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkHeading = Color(0xFFF5F5F5);
  static const Color darkSubText = Color(0xFFAAAAAA);

  // --- Glows (Low Alpha versions of primary for ambient lighting) ---
  static Color get primaryGlow => primary.withValues(alpha: 0.3);
  static Color get secondaryGlow => secondary.withValues(alpha: 0.3);
  static Color get tertiaryGlow => tertiary.withValues(alpha: 0.3);

  // --- Error Palette ---
  static const Color errorRed = Color(0xFFFF5C5C);
  static const Color errorRedDark = Color(0xFFD32F2F);
}
