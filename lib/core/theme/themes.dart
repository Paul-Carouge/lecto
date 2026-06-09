import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All available theme options.
enum AppThemeOption {
  terracotta,
  navy,
  forest,
  slate,
}

/// Palette definitions for each theme option.
class ThemePalette {
  final String name;
  final String label;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color surfaceLight;
  final Color surfaceCardLight;
  final Color surfaceDark;
  final Color surfaceCardDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnDark;

  const ThemePalette({
    required this.name,
    required this.label,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.surfaceLight,
    required this.surfaceCardLight,
    required this.surfaceDark,
    required this.surfaceCardDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnDark,
  });

  static const terracotta = ThemePalette(
    name: 'terracotta',
    label: 'Terre cuite',
    primary: Color(0xFFC85A3E),
    primaryLight: Color(0xFFD97A60),
    accent: Color(0xFFE8B84B),
    surfaceLight: Color(0xFFF8F5F0),
    surfaceCardLight: Color(0xFFFFFFFF),
    surfaceDark: Color(0xFF1C1A18),
    surfaceCardDark: Color(0xFF2A2725),
    textPrimary: Color(0xFF2A2725),
    textSecondary: Color(0xFF8B6F5C),
    textOnDark: Color(0xFFE8E2DA),
  );

  static const navy = ThemePalette(
    name: 'navy',
    label: 'Marine',
    primary: Color(0xFF1B2A4A),
    primaryLight: Color(0xFF3D5A80),
    accent: Color(0xFF98C1D9),
    surfaceLight: Color(0xFFF4F6F9),
    surfaceCardLight: Color(0xFFFFFFFF),
    surfaceDark: Color(0xFF0F1729),
    surfaceCardDark: Color(0xFF1E293B),
    textPrimary: Color(0xFF0F1729),
    textSecondary: Color(0xFF64748B),
    textOnDark: Color(0xFFE2E8F0),
  );

  static const forest = ThemePalette(
    name: 'forest',
    label: 'Forêt',
    primary: Color(0xFF2D6A4F),
    primaryLight: Color(0xFF40916C),
    accent: Color(0xFFD4A373),
    surfaceLight: Color(0xFFF5F7F3),
    surfaceCardLight: Color(0xFFFFFFFF),
    surfaceDark: Color(0xFF152B1E),
    surfaceCardDark: Color(0xFF1D3A28),
    textPrimary: Color(0xFF152B1E),
    textSecondary: Color(0xFF5A7A6A),
    textOnDark: Color(0xFFD8E5DC),
  );

  static const slate = ThemePalette(
    name: 'slate',
    label: 'Ardoise',
    primary: Color(0xFF475569),
    primaryLight: Color(0xFF64748B),
    accent: Color(0xFFF59E0B),
    surfaceLight: Color(0xFFF8FAFC),
    surfaceCardLight: Color(0xFFFFFFFF),
    surfaceDark: Color(0xFF0F172A),
    surfaceCardDark: Color(0xFF1E293B),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textOnDark: Color(0xFFE2E8F0),
  );

  /// Returns the palette for a given theme option.
  static ThemePalette fromOption(AppThemeOption option) {
    switch (option) {
      case AppThemeOption.terracotta:
        return terracotta;
      case AppThemeOption.navy:
        return navy;
      case AppThemeOption.forest:
        return forest;
      case AppThemeOption.slate:
        return slate;
    }
  }
}

/// Builds the complete ThemeData for a given palette and brightness.
class LectoTheme {
  static ThemeData build(ThemePalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final Color bg =
        isDark ? palette.surfaceDark : palette.surfaceLight;
    final Color surface =
        isDark ? palette.surfaceCardDark : palette.surfaceCardLight;
    final Color primary = isDark ? palette.primaryLight : palette.primary;
    final Color onPrimary = Colors.white;
    final Color onSurface =
        isDark ? palette.textOnDark : palette.textPrimary;
    final Color onSurfaceSecondary =
        isDark ? palette.textOnDark.withValues(alpha: 0.6) : palette.textSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: palette.accent,
        onSecondary: onPrimary,
        surface: surface,
        onSurface: onSurface,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: bg,
        foregroundColor: onSurface,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: bg,
        indicatorColor: primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onSurfaceSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: onSurfaceSecondary, size: 24);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: onSurfaceSecondary.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: onSurfaceSecondary.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: onSurfaceSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: onSurface),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: onSurfaceSecondary),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: surface,
      ),
      dividerTheme: DividerThemeData(
        color: onSurfaceSecondary.withValues(alpha: 0.12),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: surface,
      ),
    );
  }
}
