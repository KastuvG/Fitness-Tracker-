import 'dart:math';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calorie_entry.dart';
import '../services/entry_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  List<CalorieEntry> _all = [];

  // Calendar state
  DateTime _focusedDay = _stripTime(DateTime.now());
  DateTime _selectedDay = _stripTime(DateTime.now());

  // Cached grouping by day
  Map<DateTime, List<CalorieEntry>> _byDay = {};
  Map<DateTime, int> _dayTotals = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await EntryStore.loadAll();
    setState(() {
      _all = list;
      _rebuildByDay();
      _loading = false;
    });
  }

  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  void _rebuildByDay() {
    final map = <DateTime, List<CalorieEntry>>{};
    for (final e in _all) {
      final k = _stripTime(e.createdAt);
      map.putIfAbsent(k, () => []).add(e);
    }
    // sort entries newest first inside each day
    for (final k in map.keys) {
      map[k]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    // totals
    final totals = <DateTime, int>{};
    map.forEach((k, v) {
      totals[k] = v.fold(0, (s, e) => s + e.calories);
    });
    _byDay = map;
    _dayTotals = totals;
  }

  List<CalorieEntry> _entriesFor(DateTime day) {
    final k = _stripTime(day);
    return _byDay[k] ?? const [];
  }

  int _totalFor(DateTime day) => _dayTotals[_stripTime(day)] ?? 0;

  int _weeklyTotal() {
    // last 7 days including today (rolling)
    final today = _stripTime(DateTime.now());
    final since = today.subtract(const Duration(days: 6));
    return _all.where((e) {
      final d = _stripTime(e.createdAt);
      return !d.isBefore(since) && !d.isAfter(today);
    }).fold(0, (s, e) => s + e.calories);
  }

  Future<void> _showAddForSelectedDay() async {
    // Add manual entry assigned to the selected date (time will be "now" on that date)
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final cal = TextEditingController();
    final p = TextEditingController();
    final c = TextEditingController();
    final s = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add entry • ${_selectedDay.month}/${_selectedDay.day}/${_selectedDay.year}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Food / Note'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: cal,
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Enter > 0',
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: p, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Protein (g)'),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(
                  controller: c, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Carbs (g)'),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(
                  controller: s, keyboardType: TextInputType.number,
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
              int _nn(String t, {int maxVal = 100000}) {
                final v = int.tryParse(t.trim()) ?? 0;
                if (v < 0) return 0;
                if (v > maxVal) return maxVal;
                return v;
              }
              // createdAt at selected date with current time-of-day
              final now = DateTime.now();
              final createdAt = DateTime(
                  _selectedDay.year, _selectedDay.month, _selectedDay.day, now.hour, now.minute, now.second);
              final entry = CalorieEntry(
                id: '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}',
                name: name.text.trim(),
                calories: int.parse(cal.text.trim()),
                protein: _nn(p.text),
                carbs: _nn(c.text),
                sugar: _nn(s.text),
                createdAt: createdAt,
              );
              await EntryStore.add(entry);
              if (mounted) {
                Navigator.pop(ctx);
                await _reload(); // refresh calendar and list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${entry.name} to ${_selectedDay.month}/${_selectedDay.day}')),
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
        appBar: AppBar(title: const Text('History')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final selectedEntries = _entriesFor(_selectedDay);
    final weekTotal = _weeklyTotal();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _showAddForSelectedDay,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Add to date',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107), // gold/amber
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0, // flat like your reference
              ),
            ),
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // ---- Calendar ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TableCalendar<CalorieEntry>(
                  firstDay: DateTime.utc(2018, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = _stripTime(selected);
                      _focusedDay = _stripTime(focused);
                    });
                  },
                  eventLoader: (day) => _entriesFor(day),
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox.shrink();
                      final total = _totalFor(date);
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '$total',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ---- This Week total ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('This Week (last 7 days)',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '$weekTotal kcal total',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ---- Selected day details ----
            Card(
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  '${_selectedDay.month}/${_selectedDay.day}/${_selectedDay.year} • ${_totalFor(_selectedDay)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                children: selectedEntries.isEmpty
                    ? [const ListTile(title: Text('No entries for today.'))]
                    : selectedEntries
                    .map((e) => ListTile(
                  title: Text(e.name),
                  subtitle: Text(
                      '${e.calories} kcal • P ${e.protein}g • C ${e.carbs}g • S ${e.sugar}g'),
                  trailing: Text(_fmtTime(e.createdAt),
                      style: Theme.of(context).textTheme.bodySmall),
                ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}
