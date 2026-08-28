import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/startup/presentation/screens/initialization_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

/// Root widget: wires up the NovaStream theme, named routes, and decides
/// the start screen (Login vs Dashboard) based on whether a session was
/// restored from local storage.
class NovaStreamApp extends ConsumerWidget {
  const NovaStreamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Drives Material/Cupertino widget translations (dialog button labels,
    // etc.) and — importantly for Arabic — automatic RTL layout via
    // `Localizations`/`Directionality`. NovaStream's own copy (AppStrings)
    // isn't translated string-by-string here; wiring real per-string
    // translations is a drop-in addition once you're ready: run
    // `flutter gen-l10n` against .arb files and swap `AppStrings.xxx`
    // constants for `AppLocalizations.of(context)!.xxx` calls.
    final language = ref.watch(appLocaleProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      locale: Locale(language.code),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _AppEntryPoint(),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.initializing: (_) => const InitializationScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
      },
    );
  }
}

/// Chooses the first screen without a network round trip: a saved session
/// (restored by [AuthController]'s initial state) goes to
/// [InitializationScreen], which loads and pre-sorts the catalog before
/// fading into the dashboard. Without a session we go straight to login —
/// there's nothing to prepare yet.
class _AppEntryPoint extends ConsumerWidget {
  const _AppEntryPoint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    return session != null ? const InitializationScreen() : const LoginScreen();
  }
}
