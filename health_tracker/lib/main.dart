import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/database/database_service.dart';
import 'core/services/providers.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Async initialization of local databases & mock authentication
  final dbService = DatabaseService();
  await dbService.init();

  final authService = AuthService();
  await authService.init();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
        authServiceProvider.overrideWithValue(authService),
      ],
      child: const HealthSyncApp(),
    ),
  );
}

class HealthSyncApp extends ConsumerWidget {
  const HealthSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    final themeModeStr = settings.themeMode ?? 'system';

    ThemeMode themeMode;
    if (themeModeStr == 'dark') {
      themeMode = ThemeMode.dark;
    } else if (themeModeStr == 'light') {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.system;
    }

    return MaterialApp.router(
      title: 'HealthSync',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
