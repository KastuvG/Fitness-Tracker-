import 'dart:math';
import 'package:flutter/material.dart';
import '../models/weight_entry.dart';
import '../services/weight_store.dart';
import '../services/settings_store.dart';
import '../widgets/weight_trend_chart.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  bool _loading = true;
  List<WeightEntry> _all = [];
  String _unit = 'kg'; // 'kg' | 'lb'

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await WeightStore.loadAll();
    final unit = await SettingsStore.loadUnit();
    setState(() {
      _all = list;
      _unit = unit;
      _loading = false;
    });
  }

  WeightEntry? get _latest => _all.isEmpty ? null : _all.first;

  double _kgToDisplay(double kg) => _unit == 'lb' ? kg * 2.2046226218 : kg;
  double _displayToKg(double v) => _unit == 'lb' ? v / 2.2046226218 : v;
  String get _unitLabel => _unit == 'lb' ? 'lb' : 'kg';

  double? _weightDaysAgo(int days) {
    if (_all.isEmpty) return null;
    final target = DateTime.now().subtract(Duration(days: days));
    for (final e in _all) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (!d.isAfter(target)) return e.weight;
    }
    return null;
  }

  double? get _delta7d {
    final curKg = _latest?.weight;
    final pastKg = _weightDaysAgo(7);
    if (curKg == null || pastKg == null) return null;
    return _kgToDisplay(curKg) - _kgToDisplay(pastKg);
  }

  Map<String, List<WeightEntry>> _groupByMonth() {
    final map = <String, List<WeightEntry>>{};
    for (final e in _all) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(e);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in keys) k: map[k]!};
  }

  String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final weightCtrl = TextEditingController();
    final note = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String unitForInput = _unit; // default to current UI unit

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add weight'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'Weight ($unitForInput)'),
                        validator: (v) {
                          final x = double.tryParse((v ?? '').trim());
                          if (x == null || x <= 0) return '> 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: unitForInput,
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'lb', child: Text('lb')),
                      ],
                      onChanged: (v) => setLocal(() => unitForInput = v ?? 'kg'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: Text(_fmtDate(selectedDate)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2018, 1, 1),
                      lastDate: DateTime(2100, 12, 31),
                    );
                    if (picked != null) setLocal(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                  maxLines: 2,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final inputVal = double.parse(weightCtrl.text.trim());
                // Convert from chosen input unit to kg for storage:
                final kg = unitForInput == 'lb' ? inputVal / 2.2046226218 : inputVal;

                final entry = WeightEntry(
                  id: '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}',
                  weight: kg,
                  date: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
                  note: note.text.trim().isEmpty ? null : note.text.trim(),
                );
                await WeightStore.add(entry);
                if (mounted) {
                  Navigator.pop(ctx);
                  _reload();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved ${inputVal.toStringAsFixed(1)} $unitForInput on ${_fmtDate(entry.date)}')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeUnit(String u) async {
    setState(() => _unit = u);
    await SettingsStore.saveUnit(u);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weight')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final grouped = _groupByMonth();
    final latestDisp = _latest == null ? null : _kgToDisplay(_latest!.weight);
    final delta = _delta7d;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _unit,
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'lb', child: Text('lb')),
                ],
                onChanged: (v) => _changeUnit(v ?? 'kg'),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add weight'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: const Color(0xFF000000),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ---- Trend line (last 30d) ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Last 30 days', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  WeightTrendChart(entriesInKg: _all, unit: _unit),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ---- Latest + 7d change ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Latest', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    latestDisp == null ? '--' : '${latestDisp.toStringAsFixed(1)} $_unitLabel',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    delta == null
                        ? 'No 7-day comparison'
                        : (delta >= 0
                        ? '+${delta.toStringAsFixed(1)} $_unitLabel vs 7d'
                        : '${delta.toStringAsFixed(1)} $_unitLabel vs 7d'),
                    style: TextStyle(
                      color: delta == null
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : (delta > 0
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ---- Month groups ----
          if (grouped.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No weights yet. Tap "Add weight".'),
              ),
            )
          else
            ...grouped.entries.map((entry) {
              final monthKey = entry.key; // e.g., "2025-10"
              final items = entry.value;
              final parts = monthKey.split('-');
              final y = parts[0];
              final m = parts[1];
              return Card(
                child: ExpansionTile(
                  title: Text('$m/$y', style: const TextStyle(fontWeight: FontWeight.w600)),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  children: items.map((w) {
                    final disp = _kgToDisplay(w.weight);
                    return Dismissible(
                      key: ValueKey(w.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) async {
                        await WeightStore.remove(w.id);
                        _reload();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Deleted ${disp.toStringAsFixed(1)} $_unitLabel on ${_fmtDate(w.date)}')),
                          );
                        }
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.monitor_weight)),
                        title: Text('${disp.toStringAsFixed(1)} $_unitLabel'),
                        subtitle: Text(_fmtDate(w.date) + (w.note == null ? '' : ' • ${w.note}')),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
