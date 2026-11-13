import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ------------------ COLORS ------------------
  // Primary: Main brand color
  static const Color primaryGreen =
      Color(0xFF00674F); // Slightly brighter & softer

  // Secondary: Complementary color for accents/buttons
  static const Color secondaryGreen =
      const Color(0xFFFFD700); // Softer mint tone

  // Backgrounds
  static const Color lightBackground =
      Color(0xFFFDFDFD); // Soft light gray, easier on eyes than pure white
  static const Color darkBackground =
      Color(0xFF0E0E0E); // Deep, soft black-green

  // Cards
  static const Color lightCard = Color(0xFFFDFDFD); // crisp, readable
  static const Color darkCard =
      Color(0xFF121212); // soft dark card, distinct from background

  // Text
  static const Color lightTextPrimary =
      Color(0xFF1B1B1B); // dark gray, not black
  static const Color darkTextPrimary = Colors.white; // soft white for dark mode

  // ---------------- LIGHT THEME ----------------
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: lightCard,
      elevation: 0,
      iconTheme: const IconThemeData(color: primaryGreen),
      titleTextStyle: GoogleFonts.ptSansCaption(
        color: primaryGreen,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.ptSansCaption(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
      ),
      bodyMedium: GoogleFonts.ptSansCaption(
        fontSize: 18,
        color: lightTextPrimary,
      ),
    ),
    cardColor: lightCard,
    dividerColor: Colors.grey.shade300,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: secondaryGreen,
      background: lightBackground,
    ),
  );

  // ---------------- DARK THEME ----------------
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    appBarTheme: AppBarTheme(
      backgroundColor: darkCard,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.ptSansCaption(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.ptSansCaption(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyMedium: GoogleFonts.ptSansCaption(
        fontSize: 18,
        color: Colors.white.withOpacity(0.9),
      ),
    ),
    dividerColor: Colors.white10,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: secondaryGreen,
      background: darkBackground,
    ),
  );
}
