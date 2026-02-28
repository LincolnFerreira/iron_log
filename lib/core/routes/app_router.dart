import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/auth/auth_state.dart';
import 'package:iron_log/features/auth/presentation/pages/login_screen.dart';
import 'package:iron_log/features/auth/presentation/pages/splash_screen.dart';
import 'package:iron_log/features/home/home_page.dart';
import 'package:iron_log/features/onboarding/presentation/pages/methodology_setup_page.dart';
import 'package:iron_log/features/onboarding/presentation/pages/frequency_setup_page.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/presentation/pages/routines_page.dart';
import 'package:iron_log/features/routines/presentation/pages/session_edit_page.dart';
import 'package:iron_log/features/workout_creation/presentation/pages/quick_workout_creation_page.dart';
import 'package:iron_log/features/settings/presentation/pages/settings_page.dart';
import 'package:iron_log/features/workout_day/presentation/pages/workout_day_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// Mantém uma única instância do GoRouter via Riverpod para evitar reset no hot reload
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: navigatorKey,
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

      // Se já completou onboarding, evita ir para login/onboarding
      if (onboardingCompleted &&
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
          return MaterialPage(key: state.pageKey, child: const SplashScreen());
        },
      ),
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
          final routineId = state.pathParameters['routineId']!;
          final sessionId = state.pathParameters['sessionId']!;
          final session = routine.sessions.firstWhere(
            (s) => s.id == sessionId,
            orElse: () => throw Exception('Sessão não encontrada'),
          );
          return MaterialPage(
            key: state.pageKey,
            child: WorkoutDayScreen(
              routineId: routineId,
              sessionId: sessionId,
              subtitle: '${session.name} • ${routine.name}',
            ),
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
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SettingsPage()),
      ),
    ],
  );

  // Quando o estado de auth mudar, apenas pede um refresh ao router (sem recriar)
  ref.listen<AuthState>(authStateProvider, (prev, next) {
    router.refresh();
  });

  return router;
});
