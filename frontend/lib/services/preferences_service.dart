import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist app preferences such as onboarding status and last active role.
class PreferencesService {
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String _keyLastRole = 'last_active_role';

  // In-memory fallback caches
  static bool _memHasSeen = false;
  static String? _memLastRole;

  /// Check if the customer has completed or skipped the onboarding walkthrough.
  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_keyHasSeenOnboarding);
      if (val != null) {
        _memHasSeen = val;
        return val;
      }
    } catch (_) {}
    return _memHasSeen;
  }

  /// Mark onboarding as completed.
  static Future<void> setHasSeenOnboarding([bool seen = true]) async {
    _memHasSeen = seen;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasSeenOnboarding, seen);
    } catch (_) {}
  }

  /// Get the last recorded user role (e.g. 'CUSTOMER', 'RECEPTIONIST', 'MECHANIC', 'ADMIN').
  static Future<String?> getLastRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyLastRole);
      if (val != null) {
        _memLastRole = val;
        return val;
      }
    } catch (_) {}
    return _memLastRole;
  }

  /// Save the user's role to automatically skip onboarding for staff roles on subsequent launches.
  static Future<void> setLastRole(String role) async {
    _memLastRole = role.toUpperCase();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastRole, role.toUpperCase());
    } catch (_) {}
  }

  /// Reset onboarding flag (for testing or profile option).
  static Future<void> resetOnboarding() async {
    _memHasSeen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHasSeenOnboarding);
    } catch (_) {}
  }
}
