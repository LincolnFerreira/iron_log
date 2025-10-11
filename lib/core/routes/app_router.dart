import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/auth/auth_state.dart';
import 'package:iron_log/features/auth/login_screen.dart';
import 'package:iron_log/features/home/home_page.dart';
import 'package:iron_log/features/onboarding/presentation/pages/methodology_setup_page.dart';
import 'package:iron_log/features/onboarding/presentation/pages/frequency_setup_page.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/presentation/pages/routines_page.dart';
import 'package:iron_log/features/routines/presentation/pages/session_detail_page.dart';
import 'package:iron_log/features/routines/presentation/pages/session_edit_page.dart';
import 'package:iron_log/features/workout_creation/presentation/pages/quick_workout_creation_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// Mantém uma única instância do GoRouter via Riverpod para evitar reset no hot reload
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/home',
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);

      // Enquanto carrega, não redireciona
      if (authState.isLoading) return null;

      final isLoggedIn = authState.isLoggedIn;
      final onboardingCompleted = authState.onboardingCompleted;

      final atLogin = state.matchedLocation == '/login';
      final atOnboarding = state.matchedLocation.startsWith('/onboarding');
      final atMethodology = state.matchedLocation.startsWith('/methodology');

      if (!isLoggedIn) {
        // Permite ficar na tela de login
        return atLogin ? null : '/login';
      }

      if (isLoggedIn && !onboardingCompleted) {
        // Permite telas do onboarding
        if (atOnboarding || atMethodology) return null;
        return '/onboarding';
      }

      // Se já completou onboarding, evita ir para login/onboarding
      if (onboardingCompleted && (atLogin || atOnboarding || atMethodology)) {
        return '/home';
      }

      return null; // Navegação normal
    },
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
        path: '/routines/:id/edit',
        pageBuilder: (context, state) {
          final routine = state.extra as Routine;
          return MaterialPage(
            key: state.pageKey,
            child: SessionEditPage(routine: routine),
          );
        },
      ),
      GoRoute(
        path: '/routines/:routineId/sessions/:sessionId',
        pageBuilder: (context, state) {
          final routine = state.extra as Routine;
          final sessionId = state.pathParameters['sessionId']!;
          final session = routine.sessions.firstWhere(
            (s) => s.id == sessionId,
            orElse: () => throw Exception('Sessão não encontrada'),
          );
          return MaterialPage(
            key: state.pageKey,
            child: SessionDetailPage(routine: routine, session: session),
          );
        },
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

  // Quando o estado de auth mudar, apenas pede um refresh ao router (sem recriar)
  ref.listen<AuthState>(authStateProvider, (prev, next) {
    router.refresh();
  });

  return router;
});
