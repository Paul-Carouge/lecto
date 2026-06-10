import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_providers.g.dart';

// ============================================================
// Dark mode toggle
// ============================================================

/// Provider for the current theme mode preference.
///
/// Defaults to light mode. Persistence (e.g., via SharedPreferences)
/// can be added by wrapping this with a storage layer.
@Riverpod(keepAlive: true)
class ThemeModeSetting extends _$ThemeModeSetting {
  @override
  ThemeMode build() {
    return ThemeMode.light;
  }

  /// Toggles between light and dark mode.
  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  /// Sets the theme mode explicitly.
  void setTheme(ThemeMode mode) {
    state = mode;
  }

  /// Whether dark mode is currently active.
  bool get isDarkMode => state == ThemeMode.dark;

  /// Whether light mode is currently active.
  bool get isLightMode => state == ThemeMode.light;
}

/// Convenience provider for just the dark mode boolean.
@Riverpod(keepAlive: true)
bool isDarkMode(IsDarkModeRef ref) {
  return ref.watch(themeModeSettingProvider.select((mode) => mode == ThemeMode.dark));
}

// ============================================================
// User name provider (persisted via SharedPreferences)
// ============================================================

const _userNameKey = 'user_name';

/// Persisted display name for the user.
///
/// Stored in SharedPreferences. Returns an empty string when no name is set.
class UserNameNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? '';
  }

  Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    ref.invalidateSelf();
  }
}

final userNameProvider =
    AsyncNotifierProvider<UserNameNotifier, String>(UserNameNotifier.new);
