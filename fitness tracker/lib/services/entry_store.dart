import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calorie_entry.dart';

class EntryStore {
  static const _key = 'calorie_entries_v1';

  static Future<List<CalorieEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final data = (json.decode(raw) as List)
        .map((e) => CalorieEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    // newest first
    data.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return data;
  }

  static Future<void> _saveAll(List<CalorieEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(list.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> add(CalorieEntry e) async {
    final all = await loadAll();
    all.insert(0, e);
    await _saveAll(all);
  }

  static Future<void> remove(String id) async {
    final all = await loadAll();
    all.removeWhere((x) => x.id == id);
    await _saveAll(all);
  }
}
