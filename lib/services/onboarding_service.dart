import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _appOnboardingKey = 'app_onboarding_completed';

  // Check if app onboarding is completed (shown before login)
  Future<bool> isAppOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appOnboardingKey) ?? false;
  }

  // Mark app onboarding as completed
  Future<void> completeAppOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appOnboardingKey, true);
  }

  // Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appOnboardingKey);
  }

  // Reset role-specific onboarding (for logout - only resets app onboarding if needed)
  Future<void> resetRoleOnboarding() async {
    // Since we removed role-specific onboarding, this is now a no-op
    // Keeping the method for backward compatibility
  }
}
