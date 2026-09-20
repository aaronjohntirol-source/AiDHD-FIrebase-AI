import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/accessibility_settings.dart';

class AccessibilityService {
  static const _key = 'aidhd_accessibility';
  static const _legacyUsersKey = 'aidhd_users';
  static const _legacySessionKey = 'aidhd_session';

  Future<void> clearLegacyAccountData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyUsersKey);
    await prefs.remove(_legacySessionKey);
  }

  Future<AccessibilitySettings> get() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const AccessibilitySettings();
    try {
      return AccessibilitySettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AccessibilitySettings();
    }
  }

  Future<void> save(AccessibilitySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
