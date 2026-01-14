import 'package:flutter/material.dart';

// Screens
import 'screens/today_screen.dart';
import 'screens/foods_screen.dart';
import 'screens/history_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/weight_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CalorieTrackerApp());
}

class CalorieTrackerApp extends StatelessWidget {
  const CalorieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFFFC107); // amber/yellow accent

    return MaterialApp(
      title: 'Calorie Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,

      // (Optional) Light theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
      ),

      // 🌙 Dark theme with yellow accents
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF111215),
        canvasColor: const Color(0xFF111215),

        // ⬅️ CardThemeData (not CardTheme)
        cardTheme: const CardThemeData(
          color: Color(0xFF1A1B20),
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          margin: EdgeInsets.symmetric(vertical: 6),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),

// Buttons = yellow bg, dark text
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(seed),
            foregroundColor: const WidgetStatePropertyAll(Colors.black),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w700),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(seed),
            foregroundColor: const WidgetStatePropertyAll(Colors.black),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            side: WidgetStatePropertyAll(BorderSide(color: seed.withValues(alpha: 0.80))),
            foregroundColor: WidgetStatePropertyAll(seed.withValues(alpha: 0.95)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),

// Bottom Navigation
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF121318),
          elevation: 0,
          indicatorColor: seed.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? seed : Colors.white70,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(color: selected ? seed : Colors.white70);
          }),
        ),


        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF252630),
          side: const BorderSide(color: Colors.white12),
          labelStyle: const TextStyle(color: Colors.white),
          selectedColor: seed.withValues(alpha: 0.15),
          secondarySelectedColor: seed.withValues(alpha: 0.15),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1B1C22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: seed, width: 1.6),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
        ),

        // ⬅️ Use ProgressIndicatorThemeData (no LinearProgressIndicatorThemeData)
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: seed,
          linearTrackColor: Colors.white10,
        ),

        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1E1F25),
          contentTextStyle: TextStyle(color: Colors.white),
          actionTextColor: seed,
          behavior: SnackBarBehavior.floating,
          elevation: 2,
        ),
        dividerColor: Colors.white12,
        iconTheme: const IconThemeData(color: Colors.white70),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _index = 0;

  final List<Widget> _pages = const [
    TodayScreen(),
    FoodsScreen(),
    HistoryScreen(),
    WorkoutsScreen(),
    WeightScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.fastfood), label: 'Foods'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          NavigationDestination(icon: Icon(Icons.monitor_weight), label: 'Weight'),
        ],
      ),
    );
  }
}
