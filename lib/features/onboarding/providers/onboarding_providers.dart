import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key for the onboarding seen state.
const _kOnboardingSeenKey = 'lecto_onboarding_seen';

/// Whether the user has already seen the onboarding.
///
/// Returns `true` once the user has tapped "Commencer" on the last slide.
/// Consumers should watch this via `.when()` to handle loading / error states.
final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingSeenKey) ?? false;
});

/// Actions to persist the onboarding seen state.
final onboardingActionsProvider = Provider<OnboardingActions>((ref) {
  return OnboardingActions();
});

class OnboardingActions {
  /// Marks the onboarding as seen so it never shows again.
  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeenKey, true);
  }
}
