import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quarkdrop/l10n/generated/app_localizations.dart';
import 'package:quarkdrop/src/configs/desktop_layout.dart';
import 'package:quarkdrop/src/l10n/app_locale.dart';
import 'package:quarkdrop/src/screens/root_screen.dart';
import 'package:quarkdrop/src/state/app_store.dart';
import 'package:signals_flutter/signals_flutter.dart';

class QuarkDropApp extends StatelessWidget {
  const QuarkDropApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final localeCode = store.localePreferenceCode.value;
      final locale = appLocaleOptionFromCode(localeCode)?.locale;

      final themeMode = switch (store.themeMode.value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

      final lightScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFFD96A28),
        brightness: Brightness.light,
        primary: const Color(0xFFB44818),
        secondary: const Color(0xFF17766B),
        surface: const Color(0xFFF8F2E8),
      );

      final darkScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFFD96A28),
        brightness: Brightness.dark,
      );

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        locale: locale,
        themeMode: themeMode,
        supportedLocales: AppLocalizations.supportedLocales,
        localeListResolutionCallback: (locales, _) {
          return resolveSupportedAppLocale(locales);
        },
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightScheme,
          scaffoldBackgroundColor: const Color(0xFFF2EADF),
          cardTheme: const CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: Colors.white,
          ),
          navigationRailTheme: NavigationRailThemeData(
            backgroundColor: const Color(0xFFF7F0E5),
            indicatorColor: lightScheme.primary.withValues(alpha: 0.12),
            selectedIconTheme: IconThemeData(color: lightScheme.primary),
            selectedLabelTextStyle: TextStyle(
              color: lightScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: lightScheme.primary.withValues(alpha: 0.12),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: lightScheme.primary,
                  fontWeight: FontWeight.w700,
                );
              }
              return TextStyle(color: lightScheme.onSurfaceVariant);
            }),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkScheme,
          cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
          navigationRailTheme: NavigationRailThemeData(
            indicatorColor: darkScheme.primary.withValues(alpha: 0.12),
            selectedIconTheme: IconThemeData(color: darkScheme.primary),
            selectedLabelTextStyle: TextStyle(
              color: darkScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: darkScheme.primary.withValues(alpha: 0.12),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: darkScheme.primary,
                  fontWeight: FontWeight.w700,
                );
              }
              return TextStyle(color: darkScheme.onSurfaceVariant);
            }),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        ),
        home: _TrayMenuLocalizationSync(child: RootScreen(store: store)),
      );
    });
  }
}

class _TrayMenuLocalizationSync extends StatefulWidget {
  const _TrayMenuLocalizationSync({required this.child});

  final Widget child;

  @override
  State<_TrayMenuLocalizationSync> createState() =>
      _TrayMenuLocalizationSyncState();
}

class _TrayMenuLocalizationSyncState extends State<_TrayMenuLocalizationSync> {
  Locale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_lastLocale == locale) {
      return;
    }
    _lastLocale = locale;
    final l10n = AppLocalizations.of(context);
    updateDesktopTrayMenu(
      showWindowLabel: l10n.actionShowWindow,
      quitLabel: l10n.actionQuit,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
