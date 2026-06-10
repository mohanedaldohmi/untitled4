import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/browser/browser_screen.dart';
import '../../presentation/screens/player/video_player_screen.dart';
import '../../presentation/screens/premium/premium_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

/// Route paths
class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const player = '/player';
  static const premium = '/premium';
}

/// A global navigator key used by SplashScreen to push without context
class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: AppRouter.navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // Splash is a full-screen modal outside the shell
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      // Main browser screen - the primary app experience
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const BrowserScreen(),
      ),
      GoRoute(
        path: AppRoutes.player,
        builder: (context, state) {
          final filePath = state.uri.queryParameters['filePath'] ?? '';
          final title = state.uri.queryParameters['title'] ?? '';
          return VideoPlayerScreen(filePath: filePath, title: title);
        },
      ),
      GoRoute(
        path: AppRoutes.premium,
        builder: (context, state) => const PremiumScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
