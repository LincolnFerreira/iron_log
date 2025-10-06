import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/features/auth/login_screen.dart';
import 'package:iron_log/features/home/home_page.dart';
import 'package:iron_log/features/onboarding/presentation/pages/methodology_setup_page.dart';
import 'package:iron_log/features/onboarding/presentation/pages/frequency_setup_page.dart';
import 'package:iron_log/features/routines/presentation/pages/routines_page.dart';
import 'package:iron_log/features/workout_creation/presentation/pages/quick_workout_creation_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// router.dart
GoRouter createRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const FrequencySetupPage()),
      ),
      GoRoute(
        path: '/methodology',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MethodologySetupPage(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const HomePage()),
      ),
      GoRoute(
        path: '/routines',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const RoutinesPage()),
      ),
      GoRoute(
        path: '/workout/quick-create',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const QuickWorkoutCreationPage(),
        ),
      ),
    ],
  );
}
