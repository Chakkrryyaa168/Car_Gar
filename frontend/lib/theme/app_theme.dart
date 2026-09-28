import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_animations.dart';

class AppTheme {
  static TextTheme _buildTextTheme(Color primaryText, Color bodyText, Color secondaryText) {
    final baseInter = GoogleFonts.interTextTheme();
    return baseInter.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, color: primaryText),
      displayMedium: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: primaryText),
      displaySmall: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: primaryText),
      headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: primaryText),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: primaryText),
      headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: primaryText),
      titleLarge: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: primaryText),
      titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
      titleSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: secondaryText),
      bodyLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: bodyText),
      bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: bodyText),
      bodySmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: secondaryText),
      labelLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: primaryText),
      labelMedium: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: secondaryText),
      labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: secondaryText),
    );
  }

  static ThemeData get earthyCalmTheme {
    final textTheme = _buildTextTheme(AppColors.textPrimary, AppColors.textBody, AppColors.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background, // #F5F1E8 (Warm Sand)
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary, // #5F7F6B (Sage Green)
        secondary: AppColors.secondary, // #7C837E (Soft Gray-Green)
        surface: AppColors.surface, // #FFFFFF (Clean White Card)
        error: AppColors.textSecondary,
        onPrimary: Colors.white, // White text on Sage Green
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary, // #2B2F2C (Deep Charcoal)
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.topBarBackground, // #5F7F6B
        foregroundColor: AppColors.topBarText, // White
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.topBarText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.topBarText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface, // #FFFFFF
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1), // #E4DED0
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Solid Sage #5F7F6B
          foregroundColor: Colors.white, // White text
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary, // Charcoal text #2B2F2C
          side: const BorderSide(color: AppColors.border, width: 1), // Border color #E4DED0
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface, // #FFFFFF
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 20,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary, // Sage Green
        unselectedItemColor: AppColors.textSecondary, // Soft Gray-Green
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CalmPageTransitionsBuilder(),
          TargetPlatform.iOS: CalmPageTransitionsBuilder(),
          TargetPlatform.macOS: CalmPageTransitionsBuilder(),
          TargetPlatform.windows: CalmPageTransitionsBuilder(),
          TargetPlatform.linux: CalmPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CalmPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Aliases for compatibility
  static ThemeData get softCalmTheme => earthyCalmTheme;
  static ThemeData get moodyDarkTheme => earthyCalmTheme;
  static ThemeData get lightTheme => earthyCalmTheme;
  static ThemeData get darkTheme => earthyCalmTheme;
}
