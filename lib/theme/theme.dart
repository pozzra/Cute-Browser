import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class CuteTheme {
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: CuteColors.pastelPink,
      scaffoldBackgroundColor: CuteColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: CuteColors.darkText),
        titleTextStyle: TextStyle(
          color: CuteColors.darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(
        color: CuteColors.darkText,
      ),
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: CuteColors.darkText,
        displayColor: CuteColors.darkText,
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
}
