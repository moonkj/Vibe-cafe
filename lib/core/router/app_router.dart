import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../services/supabase_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);
  ref.listen(authStateProvider, (_, _) => authNotifier.value = !authNotifier.value);

  return GoRouter(
    initialLocation: '/onboarding',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final session = ref.read(supabaseClientProvider).auth.currentSession;
      final isLoggedIn = session != null;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (isLoggedIn && isOnboarding) return '/map';
      if (!isLoggedIn && !isOnboarding) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/report',
            name: 'report',
            builder: (context, state) {
              final spotId = state.uri.queryParameters['spotId'];
              final spotName = state.uri.queryParameters['spotName'] ?? '';
              return ReportScreen(spotId: spotId, spotName: spotName);
            },
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Bottom navigation shell for main app screens
class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
