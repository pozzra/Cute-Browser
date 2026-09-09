import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class CuteTheme {
  static const TargetPlatform _uniformPlatform = TargetPlatform.android;

  static const PageTransitionsTheme _uniformPageTransitions =
      PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
    },
  );

  static final ThemeData themeData = _buildTheme(isDark: false);
  static final ThemeData darkThemeData = _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final Color textColor = isDark ? CuteColors.pureWhite : CuteColors.darkText;
    final Color surfaceColor = isDark ? CuteColors.darkSurface : Colors.white;
    final Color hintColor = isDark ? CuteColors.darkSubText : CuteColors.lightText;

    return ThemeData(
      platform: _uniformPlatform,
      pageTransitionsTheme: _uniformPageTransitions,
      useMaterial3: true,
      primaryColor: CuteColors.primary,
      scaffoldBackgroundColor: isDark ? CuteColors.darkBackground : Colors.white,

      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: CuteColors.primary,
              secondary: CuteColors.secondary,
              surface: CuteColors.darkSurface,
              onSurface: CuteColors.pureWhite,
              error: CuteColors.errorRedDark,
              onError: Colors.white,
            )
          : const ColorScheme.light(
              primary: CuteColors.primary,
              secondary: CuteColors.secondary,
              surface: Colors.white,
              onSurface: CuteColors.darkText,
              error: CuteColors.errorRed,
              onError: Colors.white,
            ),

      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.nunito(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),

      iconTheme: IconThemeData(color: textColor),

      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ).copyWith(
        displayLarge: GoogleFonts.nunito(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: -1,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.5,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? CuteColors.darkSurface : Colors.white.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: CuteColors.primary, width: 2),
        ),
        hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CuteColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
