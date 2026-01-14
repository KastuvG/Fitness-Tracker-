import 'dart:math';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/food_store.dart';

class FoodsScreen extends StatefulWidget {
  const FoodsScreen({super.key});

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen> {
  List<FoodItem> _foods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await FoodStore.loadFoods();
    setState(() {
      _foods = list;
      _loading = false;
    });
  }

  Future<void> _showAddDialog() async {
    final name = TextEditingController();
    final cal = TextEditingController();
    final p = TextEditingController();
    final c = TextEditingController();
    final s = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add food'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: cal,
                  decoration: const InputDecoration(labelText: 'Calories'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                  (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Enter > 0',
                ),
                TextFormField(
                  controller: p,
                  decoration: const InputDecoration(labelText: 'Protein (g)'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                  (int.tryParse(v ?? '') ?? -1) >= 0 ? null : '>= 0',
                ),
                TextFormField(
                  controller: c,
                  decoration: const InputDecoration(labelText: 'Carbs (g)'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                  (int.tryParse(v ?? '') ?? -1) >= 0 ? null : '>= 0',
                ),
                TextFormField(
                  controller: s,
                  decoration: const InputDecoration(labelText: 'Sugar (g)'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                  (int.tryParse(v ?? '') ?? -1) >= 0 ? null : '>= 0',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final item = FoodItem(
                id: '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}',
                name: name.text.trim(),
                calories: int.parse(cal.text.trim()),
                protein: int.parse(p.text.isEmpty ? '0' : p.text.trim()),
                carbs: int.parse(c.text.isEmpty ? '0' : c.text.trim()),
                sugar: int.parse(s.text.isEmpty ? '0' : s.text.trim()),
              );
              await FoodStore.addFood(item);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved "${item.name}"')),
                );
                _reload();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foods')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Food To Store'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: const Color(0xFF000000),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _foods.isEmpty
          ? const Center(child: Text('No saved foods. Tap "Add food".'))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _foods.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final f = _foods[i];
          return Dismissible(
            key: ValueKey(f.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Icon(Icons.delete,
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            onDismissed: (_) async {
              await FoodStore.removeFood(f.id);
              setState(() => _foods.removeAt(i));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${f.name}"'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        await FoodStore.addFood(f);
                        _reload();
                      },
                    ),
                  ),
                );
              }
            },
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.fastfood)),
              title: Text(f.name),
              subtitle: Text(
                '${f.calories} kcal • P ${f.protein}g • C ${f.carbs}g • S ${f.sugar}g',
              ),
            ),
          );
        },
      ),
    );
  }
}
