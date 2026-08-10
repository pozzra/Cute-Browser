import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class CuteTheme {
  // Force the same Material look & behavior on Android and iOS.
  static const TargetPlatform _uniformPlatform = TargetPlatform.android;

  static const PageTransitionsTheme _uniformPageTransitions =
      PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    },
  );

  static ThemeData get themeData {
    return ThemeData(
      platform: _uniformPlatform,
      pageTransitionsTheme: _uniformPageTransitions,
      primaryColor: CuteColors.pastelPink,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: CuteColors.pastelPink,
        secondary: CuteColors.softPurple,
        surface: Colors.white,
        onSurface: Colors.black,
        error: CuteColors.errorPink,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.black,
      ),
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
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
        hintStyle: const TextStyle(color: CuteColors.lightText),
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

  static ThemeData get darkThemeData {
    return ThemeData(
      platform: _uniformPlatform,
      pageTransitionsTheme: _uniformPageTransitions,
      primaryColor: CuteColors.pastelPink,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: CuteColors.pastelPink,
        secondary: CuteColors.softPurple,
        surface: Colors.black,
        onSurface: Colors.white,
        error: CuteColors.darkErrorPink,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CuteColors.darkSurface,
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
        hintStyle: const TextStyle(color: CuteColors.darkSubText),
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
