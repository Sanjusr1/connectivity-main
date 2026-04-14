import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryDark = Color(0xFF07111F);
  static const Color primaryMid = Color(0xFF0F1E33);
  static const Color surfaceDark = Color(0xFF111C2D);
  static const Color surfaceCard = Color(0xFF162338);
  static const Color surfaceCardLight = Color(0xFF1D2D45);
  static const Color accentCyan = Color(0xFF4FB3FF);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentPink = Color(0xFFF472B6);
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentYellow = Color(0xFFFBBF24);
  static const Color textPrimary = Color(0xFFF3F7FB);
  static const Color textSecondary = Color(0xFFB5C2D1);
  static const Color textMuted = Color(0xFF6C7D91);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningYellow = Color(0xFFF59E0B);

  static List<Color> sensorColors = [
    accentCyan,
    accentPink,
    accentTeal,
    accentOrange,
    accentPurple,
    accentBlue,
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentTeal,
        surface: surfaceDark,
        error: dangerRed,
        onPrimary: primaryDark,
        onSecondary: primaryDark,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: accentCyan,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 2,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceCardLight,
        selectedColor: accentCyan.withValues(alpha: 0.20),
        checkmarkColor: accentCyan,
        labelStyle: const TextStyle(color: textPrimary),
        side: BorderSide(color: textMuted.withValues(alpha: 0.22)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: primaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentCyan,
          side: BorderSide(color: accentCyan.withValues(alpha: 0.36)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentCyan;
          }
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentCyan.withValues(alpha: 0.28);
          }
          return surfaceCardLight;
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: accentCyan),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryMid,
        selectedItemColor: accentCyan,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentCyan,
        foregroundColor: primaryDark,
        elevation: 8,
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A3A4A),
        thickness: 1,
      ),
    );
  }

  static BoxDecoration get glassCard => BoxDecoration(
    color: surfaceCard.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: textMuted.withValues(alpha: 0.16), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.24),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration glassCardWithColor(Color color) => BoxDecoration(
    color: surfaceCard.withValues(alpha: 0.94),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.22),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, Color(0xFF0B1728), Color(0xFF101827)],
  );

  static LinearGradient get glossOverlayGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.10),
      Colors.transparent,
      accentCyan.withValues(alpha: 0.05),
    ],
    stops: const [0, 0.38, 1],
  );

  static LinearGradient accentGradient(Color color) =>
      LinearGradient(colors: [color, color.withValues(alpha: 0.6)]);
}
