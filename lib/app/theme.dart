// lib/app/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: kCardColor,
          foregroundColor: kTextPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: kTextPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 4,
            shadowColor: kPrimaryColor.withOpacity(0.3),
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: kTextPrimary,
          displayColor: kTextPrimary,
        ).copyWith(
          headlineLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: kTextPrimary),
          headlineMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: kTextPrimary),
          titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: kTextPrimary),
          bodyLarge: GoogleFonts.poppins(fontSize: 16, color: kTextPrimary),
          bodyMedium: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
          labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary),
        ),
        cardTheme: CardThemeData(
  color: kCardColor,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
  elevation: 4,
  shadowColor: Colors.black26,
),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kCardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius), borderSide: BorderSide(color: kTextSecondary.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius), borderSide: const BorderSide(color: kPrimaryColor)),
          labelStyle: GoogleFonts.poppins(color: kTextSecondary),
        ),
      );
}
