import 'package:shared_preferences/shared_preferences.dart';

class AiKeyService {
  static const _keyPrefix = 'gemini_api_key_';

  Future<String?> getKey(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('$_keyPrefix$userId')?.trim();
    return key == null || key.isEmpty ? null : key;
  }

  Future<void> saveKey(String userId, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$userId', key.trim());
  }

  Future<void> removeKey(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$userId');
  }
}
