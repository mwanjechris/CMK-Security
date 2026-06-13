import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'screens/app_locker/app_locker_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/file_locker/file_locker_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/setup/pattern_setup_screen.dart';
import 'screens/setup/permissions_screen.dart';
import 'screens/setup/pin_setup_screen.dart';
import 'screens/setup/setup_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/vault/vault_screen.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/setup', builder: (_, __) => const SetupScreen()),
    GoRoute(path: '/setup/pin', builder: (_, __) => const PinSetupScreen()),
    GoRoute(path: '/setup/pattern', builder: (_, __) => const PatternSetupScreen()),
    GoRoute(path: '/permissions', builder: (_, __) => const PermissionsScreen()),
    GoRoute(
      path: '/auth',
      builder: (_, state) => AuthScreen(
        redirectTo: state.uri.queryParameters['redirect'],
      ),
    ),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/app-locker', builder: (_, __) => const AppLockerScreen()),
    GoRoute(path: '/file-locker', builder: (_, __) => const FileLockerScreen()),
    GoRoute(path: '/vault', builder: (_, __) => const VaultScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

class CmkSecurityApp extends StatelessWidget {
  const CmkSecurityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CMK Security',
      theme: AppTheme.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
