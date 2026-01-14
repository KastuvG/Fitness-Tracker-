import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_entry.dart';

class WorkoutStore {
  static const _key = 'workouts_v1';

  static Future<List<WorkoutEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (json.decode(raw) as List)
        .map((e) => WorkoutEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
    return list;
  }

  static Future<void> _saveAll(List<WorkoutEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(list.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> add(WorkoutEntry e) async {
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
