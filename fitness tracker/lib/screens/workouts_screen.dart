import 'dart:math';
import 'package:flutter/material.dart';
import '../models/workout_entry.dart';
import '../services/workout_store.dart';

const _bodyParts = <String>[
  'Chest','Back','Legs','Shoulders','Arms','Core','Full Body','Other'
];

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  bool _loading = true;
  List<WorkoutEntry> _all = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await WorkoutStore.loadAll();
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  // Find the best (PR) per exercise: max weight, tiebreaker reps.
  Map<String, WorkoutEntry> _prsByExercise() {
    final best = <String, WorkoutEntry>{};
    for (final e in _all) {
      final ex = e.exercise.toLowerCase();
      if (!best.containsKey(ex)) {
        best[ex] = e;
      } else {
        final cur = best[ex]!;
        if (e.weight > cur.weight || (e.weight == cur.weight && e.reps > cur.reps)) {
          best[ex] = e;
        }
      }
    }
    return best;
  }

  Map<String, List<WorkoutEntry>> _groupByBodyPart() {
    final map = <String, List<WorkoutEntry>>{};
    for (final e in _all) {
      map.putIfAbsent(e.bodyPart, () => []).add(e);
    }
    // keep newest first inside each group
    for (final k in map.keys) {
      map[k]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final keys = map.keys.toList()..sort();
    return {for (final k in keys) k: map[k]!};
  }

  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final exercise = TextEditingController();
    final weight = TextEditingController();
    final reps = TextEditingController();
    final notes = TextEditingController();
    String bodyPart = _bodyParts.first;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add workout set'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: exercise,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Exercise'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: bodyPart,
                  items: _bodyParts
                      .map((bp) => DropdownMenuItem(value: bp, child: Text(bp)))
                      .toList(),
                  onChanged: (v) => bodyPart = v ?? bodyPart,
                  decoration: const InputDecoration(labelText: 'Body part'),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Weight'),
                      validator: (v) {
                        final x = double.tryParse((v ?? '').trim());
                        if (x == null || x < 0) return '>= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: reps,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps'),
                      validator: (v) {
                        final x = int.tryParse((v ?? '').trim());
                        if (x == null || x <= 0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
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
              final entry = WorkoutEntry(
                id: '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}',
                exercise: exercise.text.trim(),
                bodyPart: bodyPart,
                weight: double.parse(weight.text.trim()),
                reps: int.parse(reps.text.trim()),
                createdAt: DateTime.now(),
                notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
              );
              await WorkoutStore.add(entry);
              if (mounted) {
                Navigator.pop(ctx);
                _reload();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${entry.exercise} (${entry.weight} × ${entry.reps})')),
                );
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workouts')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final grouped = _groupByBodyPart();
    final prs = _prsByExercise();

    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Workout set'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: const Color(0xFF000000),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),

      body: grouped.isEmpty
          ? const Center(child: Text('No workouts yet. Tap "Add set".'))
          : ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final bp in grouped.keys) ...[
            Card(
              child: ExpansionTile(
                title: Text(bp, style: const TextStyle(fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: grouped[bp]!
                    .map((e) => _WorkoutTile(
                  e: e,
                  isPR: () {
                    final key = e.exercise.toLowerCase();
                    final best = prs[key];
                    if (best == null) return false;
                    return best.weight == e.weight && best.reps == e.reps;
                  }(),
                  onDelete: () async {
                    await WorkoutStore.remove(e.id);
                    _reload();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Deleted ${e.exercise} set')),
                      );
                    }
                  },
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutEntry e;
  final bool isPR;
  final VoidCallback onDelete;
  const _WorkoutTile({required this.e, required this.isPR, required this.onDelete});

  String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$m/$day/${d.year} • $h:$min $ampm';
    // (No intl package needed)
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: isPR ? const Icon(Icons.emoji_events) : const Icon(Icons.fitness_center),
        ),
        title: Text('${e.exercise}  •  ${e.weight} × ${e.reps}${isPR ? "  (PR)" : ""}'),
        subtitle: Text(_fmtDate(e.createdAt) + (e.notes == null ? '' : '  •  ${e.notes}')),
      ),
    );
  }
}
