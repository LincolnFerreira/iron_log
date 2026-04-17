import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/auth/auth_state.dart';
import 'package:iron_log/features/auth/presentation/pages/login_screen.dart';
import 'package:iron_log/features/auth/presentation/pages/splash_screen.dart';
import 'package:iron_log/features/home/home_page.dart';
import 'package:iron_log/features/onboarding/presentation/pages/methodology_setup_page.dart';
import 'package:iron_log/features/onboarding/presentation/pages/frequency_setup_page.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/presentation/pages/routines_page.dart';
import 'package:iron_log/features/routines/presentation/pages/routine_sessions_page.dart';
import 'package:iron_log/features/routines/presentation/pages/session_editor_page.dart';
import 'package:iron_log/features/workout_creation/presentation/pages/quick_workout_creation_page.dart';
import 'package:iron_log/features/settings/presentation/pages/settings_page.dart';
import 'package:iron_log/features/workout_history/presentation/pages/workout_history_page.dart';
import 'package:iron_log/features/workout_day/presentation/pages/cardio_creation_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// Route observer usado para detectar quando páginas voltam a ficar visíveis
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

// Mantém uma única instância do GoRouter via Riverpod para evitar reset no hot reload
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: navigatorKey,
    observers: [routeObserver],
    initialLocation: '/', // Usar rota raiz, deixar o redirect decidir
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);

      // Debug: Log do estado atual
      print(
        '🔀 Router redirect - isLoading: ${authState.isLoading}, isLoggedIn: ${authState.isLoggedIn}, location: ${state.matchedLocation}',
      );

      final isLoggedIn = authState.isLoggedIn;
      final onboardingCompleted = authState.onboardingCompleted;

      final atLogin = state.matchedLocation == '/login';
      final atRoot = state.matchedLocation == '/';
      final atOnboarding = state.matchedLocation.startsWith('/onboarding');
      final atMethodology = state.matchedLocation.startsWith('/methodology');

      // Se não está logado, deve ir para login
      if (!isLoggedIn && !authState.isLoading) {
        print('🔀 Redirecionando para login - usuário não logado');
        return '/login';
      }

      // Se está carregando, não redireciona (mostra splash na rota /)
      if (authState.isLoading) {
        print('🔀 Estado carregando, mantendo rota atual');
        return null;
      }

      if (isLoggedIn && !onboardingCompleted) {
        // Permite telas do onboarding
        if (atOnboarding || atMethodology) return null;
        return '/onboarding';
      }

      // Se já completou onboarding e está logado, evita ir para login/onboarding
      if (isLoggedIn &&
          onboardingCompleted &&
          (atLogin || atOnboarding || atMethodology || atRoot)) {
        return '/home';
      }

      return null; // Navegação normal
    },
    routes: [
      // Rota raiz - mostra splash quando carregando, senão é redirecionada
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          final authState = ref.read(authStateProvider);
          if (authState.isLoading) {
            return MaterialPage(
              key: state.pageKey,
              child: const SplashScreen(),
            );
          }
          return AppPage(key: state.pageKey, child: const SplashScreen());
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            AppPage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            AppPage(key: state.pageKey, child: const FrequencySetupPage()),
      ),
      GoRoute(
        path: '/methodology',
        pageBuilder: (context, state) =>
            AppPage(key: state.pageKey, child: const MethodologySetupPage()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            AppPage(key: state.pageKey, child: const HomePage()),
      ),
      GoRoute(
        path: '/routines',
        pageBuilder: (context, state) =>
            AppPage(key: state.pageKey, child: const RoutinesPage()),
      ),
      GoRoute(
        path: '/routines/:id/edit',
        pageBuilder: (context, state) {
          final routine = state.extra as Routine;
          return AppPage(
            key: state.pageKey,
            child: RoutineSessionsPage(routine: routine),
          );
        },
      ),
      GoRoute(
        path: '/routines/:routineId/sessions/new',
        pageBuilder: (context, state) {
          final routine = state.extra as Routine;
          return AppPage(
            key: state.pageKey,
            child: SessionEditorPage(routine: routine),
          );
        },
      ),
      GoRoute(
        path: '/routines/:routineId/sessions/:sessionId',
        pageBuilder: (context, state) {
          final routine = state.extra as Routine;
          final sessionId = state.pathParameters['sessionId']!;
          return AppPage(
            key: state.pageKey,
            child: SessionEditorPage(routine: routine, sessionId: sessionId),
          );
        },
      ),
      GoRoute(
        path: '/workout/quick-create',
        pageBuilder: (context, state) => AppPage(
          key: state.pageKey,
          child: const QuickWorkoutCreationPage(),
        ),
      ),
      GoRoute(
        path: '/cardio-creation',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final date = extra?['date'] as DateTime?;
          return AppPage(
            key: state.pageKey,
            child: CardioCreationPage(initialDate: date),
          );
        },
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) =>
            AppPage(key: state.pageKey, child: const WorkoutHistoryPage()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            AppPage(key: state.pageKey, child: const SettingsPage()),
      ),
    ],
  );

  // Quando o estado de auth mudar, apenas pede um refresh ao router (sem recriar)
  ref.listen<AuthState>(authStateProvider, (prev, next) {
    router.refresh();
  });

  return router;
});
