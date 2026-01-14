import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  static const _unitKey = 'unit_pref_v1'; // 'kg' | 'lb'

  static Future<String> loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_unitKey) ?? 'kg';
  }

  static Future<void> saveUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, unit);
  }

  static bool get isKg => true; // convenience if ever needed
}
