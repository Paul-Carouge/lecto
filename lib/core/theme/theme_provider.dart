import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themes.dart';

/// Key for persisting the selected theme option.
const _kThemeKey = 'lecto_theme_option';
const _kDarkModeKey = 'lecto_dark_mode';

/// Provider that gives access to the full theme palette for the current theme.
final themePaletteProvider = Provider<ThemePalette>((ref) {
  return ref.watch(appThemeProvider);
});

/// Provider for the current theme option (which palette).
final themeOptionProvider = StateNotifierProvider<ThemeOptionNotifier, AppThemeOption>(
  (ref) => ThemeOptionNotifier(),
);

/// Provider for dark/light mode toggle.
final isDarkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>(
  (ref) => DarkModeNotifier(),
);

/// Combined provider that returns the effective ThemePalette.
final appThemeProvider = Provider<ThemePalette>((ref) {
  final option = ref.watch(themeOptionProvider);
  return ThemePalette.fromOption(option);
});

/// Returns the current ThemeData (light or dark) for use in MaterialApp.
final themeDataProvider = Provider<ThemeData>((ref) {
  final palette = ref.watch(appThemeProvider);
  final isDark = ref.watch(isDarkModeProvider);
  return LectoTheme.build(palette, isDark ? Brightness.dark : Brightness.light);
});

// ============================================================
// Theme Option Notifier
// ============================================================

class ThemeOptionNotifier extends StateNotifier<AppThemeOption> {
  ThemeOptionNotifier() : super(AppThemeOption.terracotta) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemeKey);
      if (saved != null) {
        state = AppThemeOption.values.firstWhere(
          (o) => o.name == saved,
          orElse: () => AppThemeOption.terracotta,
        );
      }
    } catch (_) {
      // Default: terracotta
    }
  }

  Future<void> setTheme(AppThemeOption option) async {
    state = option;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeKey, option.name);
    } catch (_) {
      // Silently fail — theme still applies for this session
    }
  }
}

// ============================================================
// Dark Mode Notifier
// ============================================================

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_kDarkModeKey) ?? false;
    } catch (_) {
      // Default: light mode
    }
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDarkModeKey, state);
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> setDarkMode(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDarkModeKey, value);
    } catch (_) {
      // Silently fail
    }
  }
}
