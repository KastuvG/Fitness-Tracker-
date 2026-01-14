import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';

class FoodStore {
  static const _key = 'saved_foods_v1';

  static Future<List<FoodItem>> loadFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (json.decode(raw) as List)
        .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  static Future<void> saveFoods(List<FoodItem> foods) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(foods.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<void> addFood(FoodItem food) async {
    final list = await loadFoods();
    list.insert(0, food);
    await saveFoods(list);
  }

  static Future<void> removeFood(String id) async {
    final list = await loadFoods();
    list.removeWhere((f) => f.id == id);
    await saveFoods(list);
  }
}
