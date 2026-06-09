// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isDarkModeHash() => r'd5d5906bfc07a9df8c50c50520176d80a752188e';

/// Convenience provider for just the dark mode boolean.
///
/// Copied from [isDarkMode].
@ProviderFor(isDarkMode)
final isDarkModeProvider = Provider<bool>.internal(
  isDarkMode,
  name: r'isDarkModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isDarkModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsDarkModeRef = ProviderRef<bool>;
String _$themeModeSettingHash() => r'560d10d6ee7994f3dd2469fe4137b8638f491828';

/// Provider for the current theme mode preference.
///
/// Defaults to light mode. Persistence (e.g., via SharedPreferences)
/// can be added by wrapping this with a storage layer.
///
/// Copied from [ThemeModeSetting].
@ProviderFor(ThemeModeSetting)
final themeModeSettingProvider =
    NotifierProvider<ThemeModeSetting, ThemeMode>.internal(
      ThemeModeSetting.new,
      name: r'themeModeSettingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$themeModeSettingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ThemeModeSetting = Notifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
