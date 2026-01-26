import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _appOnboardingKey = 'app_onboarding_completed';
  static const String _customerOnboardingKey = 'customer_onboarding_completed';
  static const String _vendorOnboardingKey = 'vendor_onboarding_completed';

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

  // Check if customer onboarding is completed
  Future<bool> isCustomerOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_customerOnboardingKey) ?? false;
  }

  // Check if vendor onboarding is completed
  Future<bool> isVendorOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vendorOnboardingKey) ?? false;
  }

  // Mark customer onboarding as completed
  Future<void> completeCustomerOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_customerOnboardingKey, true);
  }

  // Mark vendor onboarding as completed
  Future<void> completeVendorOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vendorOnboardingKey, true);
  }

  // Reset onboarding (for testing or logout)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appOnboardingKey);
    await prefs.remove(_customerOnboardingKey);
    await prefs.remove(_vendorOnboardingKey);
  }
}
