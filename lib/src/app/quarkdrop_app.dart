import 'package:flutter/material.dart';
import 'package:quarkdrop/src/screens/root_screen.dart';
import 'package:quarkdrop/src/state/app_store.dart';

class QuarkDropApp extends StatelessWidget {
  const QuarkDropApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD96A28),
      brightness: Brightness.light,
      primary: const Color(0xFFB44818),
      secondary: const Color(0xFF17766B),
      surface: const Color(0xFFF8F2E8),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuarkDrop',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF2EADF),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: const Color(0xFFF7F0E5),
          indicatorColor: scheme.primary.withValues(alpha: 0.12),
          selectedIconTheme: IconThemeData(color: scheme.primary),
          selectedLabelTextStyle: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: scheme.primary.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              );
            }
            return TextStyle(color: scheme.onSurfaceVariant);
          }),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: RootScreen(store: store),
    );
  }
}
