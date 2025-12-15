import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'color_palette.dart';

class AppTheme {
  static TextTheme _instagramTextTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final primaryColor = brightness == Brightness.dark
        ? AppColors.textLight
        : AppColors.textDark;
    final secondaryColor = brightness == Brightness.dark
        ? AppColors.textGrey
        : Colors.black54;

    return GoogleFonts.interTextTheme(base).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: secondaryColor),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: secondaryColor),
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: primaryColor,
      ),
    );
  }

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    fontFamily: GoogleFonts.inter().fontFamily,

    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
    ),

    scaffoldBackgroundColor: Colors.white,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    textTheme: _instagramTextTheme(Brightness.light),
    extensions: const [AppPalette.light],

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    fontFamily: GoogleFonts.inter().fontFamily,

    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
    ),

    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    textTheme: _instagramTextTheme(Brightness.dark),
    extensions: const [AppPalette.dark],
  );
}
