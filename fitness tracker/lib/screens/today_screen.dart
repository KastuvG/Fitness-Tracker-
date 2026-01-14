import 'package:flutter/material.dart';
import 'dart:math';
import '../models/calorie_entry.dart';
import '../services/entry_store.dart';
import '../services/food_store.dart';
import '../models/food_item.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final List<CalorieEntry> _entries = [];
  final int dailyGoal = 2000;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    final all = await EntryStore.loadAll();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final todays = all
        .where((e) =>
    e.createdAt.isAfter(start.subtract(const Duration(microseconds: 1))) &&
        e.createdAt.isBefore(end))
        .toList();
    setState(() {
      _entries
        ..clear()
        ..addAll(todays);
    });
  }

  int get totalCalories => _entries.fold(0, (sum, e) => sum + e.calories);
  int get totalProtein => _entries.fold(0, (s, e) => s + e.protein);
  int get totalCarbs => _entries.fold(0, (s, e) => s + e.carbs);
  int get totalSugar => _entries.fold(0, (s, e) => s + e.sugar);

  int _parseNonNeg(String s, {int maxVal = 100000}) {
    final v = int.tryParse(s.trim()) ?? 0;
    if (v < 0) return 0;
    if (v > maxVal) return maxVal;
    return v;
  }

  Future<void> _addEntry(CalorieEntry entry) async {
    setState(() => _entries.insert(0, entry));
    await EntryStore.add(entry);
  }

  Future<void> _showAddEntryDialog() async {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    final cCtrl = TextEditingController();
    final sCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add manual entry'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Food / Note'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: calCtrl,
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Enter > 0',
              ),
              Row(children: [
                Expanded(
                    child: TextFormField(
                      controller: pCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                    )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextFormField(
                      controller: cCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Carbs (g)'),
                    )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextFormField(
                      controller: sCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sugar (g)'),
                    )),
              ]),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final entry = CalorieEntry(
                id: '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}',
                name: nameCtrl.text.trim(),
                calories: int.parse(calCtrl.text.trim()),
                protein: _parseNonNeg(pCtrl.text),
                carbs: _parseNonNeg(cCtrl.text),
                sugar: _parseNonNeg(sCtrl.text),
                createdAt: DateTime.now(),
              );
              await _addEntry(entry);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${entry.name} (+${entry.calories} kcal)')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSavedFoodsSheet() async {
    final foods = await FoodStore.loadFoods();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => foods.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No saved foods yet. Add some on the Foods tab.'),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: foods.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final f = foods[i];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.fastfood)),
            title: Text(f.name),
            subtitle: Text(
                '${f.calories} kcal • P ${f.protein}g • C ${f.carbs}g • S ${f.sugar}g'),
            trailing: FilledButton(
              onPressed: () async {
                final entry = CalorieEntry(
                  id:
                  '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}',
                  name: f.name,
                  calories: f.calories,
                  protein: f.protein,
                  carbs: f.carbs,
                  sugar: f.sugar,
                  createdAt: DateTime.now(),
                );
                await _addEntry(entry);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${f.name} from saved foods')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = dailyGoal - totalCalories;
    final progress = (totalCalories / dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      // App name shown in the top bar
      appBar: AppBar(title: const Text('My Fitness Tracker'), centerTitle: true),

      // ✅ No floating buttons blocking the view
      floatingActionButton: null,
      floatingActionButtonLocation: null,

      // ✅ Side-by-side actions anchored at the bottom
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _showSavedFoodsSheet,
                  icon: const Icon(Icons.bookmarks_outlined),
                  label: const Text('Add from saved'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _showAddEntryDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add manual'),
                ),
              ),
            ],
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            total: totalCalories,
            goal: dailyGoal,
            remaining: remaining,
            progress: progress,
            p: totalProtein,
            c: totalCarbs,
            s: totalSugar,
          ),
          const SizedBox(height: 12),
          if (_entries.isEmpty)
            _EmptyState(
              onAddTap: _showAddEntryDialog,
              onAddFromSaved: _showSavedFoodsSheet,
            )
          else
            ..._entries.map(
                  (e) => Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Icon(Icons.delete,
                      color: Theme.of(context).colorScheme.onErrorContainer),
                ),
                onDismissed: (_) async {
                  final removed = e;
                  setState(() => _entries.removeWhere((x) => x.id == e.id));
                  await EntryStore.remove(removed.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted ${removed.name}'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () async {
                            setState(() => _entries.insert(0, removed));
                            await EntryStore.add(removed);
                          },
                        ),
                      ),
                    );
                  }
                },
                child: _EntryTile(entry: e),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ---- UI bits ----
class _SummaryCard extends StatelessWidget {
  final int total, goal, remaining;
  final double progress;
  final int p, c, s;
  const _SummaryCard({
    required this.total,
    required this.goal,
    required this.remaining,
    required this.progress,
    required this.p,
    required this.c,
    required this.s,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('Calories Today', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('$total / $goal kcal',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.center, spacing: 16, children: [
            Chip(label: Text('Protein: ${p}g')),
            Chip(label: Text('Carbs: ${c}g')),
            Chip(label: Text('Sugar: ${s}g')),
          ]),
          const SizedBox(height: 8),
          Text(
            remaining >= 0 ? '${remaining} kcal remaining' : '${remaining.abs()} kcal over',
            style: TextStyle(color: remaining >= 0 ? scheme.primary : scheme.error),
          ),
        ]),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final CalorieEntry entry;
  const _EntryTile({required this.entry});
  @override
  Widget build(BuildContext context) {
    final dt = entry.createdAt;
    final time =
        '${dt.month}/${dt.day}/${dt.year} • ${(dt.hour % 12 == 0) ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.restaurant)),
      title: Text(entry.name),
      subtitle: Text(
          '${entry.calories} kcal • P ${entry.protein}g • C ${entry.carbs}g • S ${entry.sugar}g • $time'),
      trailing: Text('+${entry.calories}', style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  final VoidCallback onAddFromSaved;
  const _EmptyState({required this.onAddTap, required this.onAddFromSaved});
  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Icon(Icons.assignment_add, size: 42),
          const SizedBox(height: 12),
          const Text('No entries yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Tap a button below to get started.',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onAddFromSaved,
                  icon: const Icon(Icons.bookmarks_outlined),
                  label: const Text('Add from saved'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddTap,
                  icon: const Icon(Icons.add),
                  label: const Text('Add manual'),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
