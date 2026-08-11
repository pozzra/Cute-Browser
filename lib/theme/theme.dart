import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class CuteTheme {
  // Force the same Material look & behavior on Android and iOS.
  static const TargetPlatform _uniformPlatform = TargetPlatform.android;

  // Modern, identical page transitions on every platform.
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

  // Pre-computed once so the app boots fast (avoids repeated font/layout work).
  static final ThemeData themeData = _buildTheme(isDark: false);
  static final ThemeData darkThemeData = _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color inputFill = isDark ? CuteColors.darkSurface : Colors.white;
    final Color hintColor = isDark ? CuteColors.darkSubText : CuteColors.lightText;

    return ThemeData(
      platform: _uniformPlatform,
      pageTransitionsTheme: _uniformPageTransitions,
      primaryColor: CuteColors.pastelPink,
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: CuteColors.pastelPink,
              secondary: CuteColors.softPurple,
              surface: Colors.black,
              onSurface: Colors.white,
              error: CuteColors.darkErrorPink,
              onError: Colors.white,
            )
          : const ColorScheme.light(
              primary: CuteColors.pastelPink,
              secondary: CuteColors.softPurple,
              surface: Colors.white,
              onSurface: Colors.black,
              error: CuteColors.errorPink,
              onError: Colors.white,
            ),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: IconThemeData(color: textColor),
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: CuteColors.pastelPink, width: 2),
        ),
        hintStyle: TextStyle(color: hintColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CuteColors.pastelPink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
        ),
      ),
      useMaterial3: true,
    );
  }
}
