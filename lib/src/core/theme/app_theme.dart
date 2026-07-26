import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF1A1F2E);
  static const Color _accent = Color(0xFFB8945F);

  static const Map<String, double> _languageFontScale = {
    'he': 1.18,
    'ar': 1.35,
  };

  static ThemeData light({Locale? locale}) =>
      _build(Brightness.light, locale: locale);
  static ThemeData dark({Locale? locale}) =>
      _build(Brightness.dark, locale: locale);

  static ThemeData _build(Brightness brightness, {Locale? locale}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      secondary: _accent,
      tertiary: const Color(0xFFC9B89E),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
    );

    final scale = _languageFontScale[locale?.languageCode] ?? 1.0;

    final textTheme = GoogleFonts.rubikTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.rubik(
        fontSize: 64 * scale,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        color: scheme.onSurface,
        height: 1.05,
      ),
      displayMedium: GoogleFonts.rubik(
        fontSize: 48 * scale,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: scheme.onSurface,
        height: 1.05,
      ),
      headlineLarge: GoogleFonts.rubik(
        fontSize: 36 * scale,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        color: scheme.onSurface,
        height: 1.1,
      ),
      headlineMedium: GoogleFonts.rubik(
        fontSize: 28 * scale,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: scheme.onSurface,
        height: 1.15,
      ),
      titleLarge: GoogleFonts.rubik(
        fontSize: 20 * scale,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      bodyLarge: GoogleFonts.rubik(
        fontSize: 18 * scale,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.rubik(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.rubik(
        fontSize: 17 * scale,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, KioskTokens.touchTargetLarge),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          iconSize: 30,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 24 * scale),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, KioskTokens.touchTargetLarge),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          side: BorderSide(color: scheme.outline, width: 1.5),
          iconSize: 30,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 24 * scale),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
    );
  }
}

class KioskTokens {
  KioskTokens._();

  static const double touchTargetSmall = 56;
  static const double touchTargetLarge = 80;
  static const double touchTargetHero = 120;

  /// Max width for form/settings content so input rows stay a comfortable
  /// size on large tablets instead of stretching edge-to-edge.
  static const double maxContentWidth = 720;

  static const double radiusSmall = 12;
  static const double radiusMedium = 24;
  static const double radiusLarge = 32;
  static const double radiusXLarge = 48;

  static const double spaceXS = 8;
  static const double spaceS = 16;
  static const double spaceM = 24;
  static const double spaceL = 32;
  static const double spaceXL = 48;
  static const double spaceXXL = 64;

  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionMedium = Duration(milliseconds: 360);
  static const Duration motionSlow = Duration(milliseconds: 600);
}
