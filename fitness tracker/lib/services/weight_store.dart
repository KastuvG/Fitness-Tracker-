import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weight_entry.dart';

class WeightStore {
  static const _key = 'weights_v1';

  static Future<List<WeightEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (json.decode(raw) as List)
        .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    // sort newest first
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<void> _saveAll(List<WeightEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(list.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> add(WeightEntry e) async {
    final all = await loadAll();
    // if an entry for the same date exists, replace it
    final key = DateTime(e.date.year, e.date.month, e.date.day);
    final idx = all.indexWhere((x) =>
    x.date.year == key.year && x.date.month == key.month && x.date.day == key.day);
    if (idx >= 0) {
      all[idx] = e;
    } else {
      all.insert(0, e);
    }
    await _saveAll(all);
  }

  static Future<void> remove(String id) async {
    final all = await loadAll();
    all.removeWhere((x) => x.id == id);
    await _saveAll(all);
  }
}
