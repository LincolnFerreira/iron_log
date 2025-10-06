import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/app_theme.dart';
import 'core/routes/app_router.dart';
import 'features/auth/auth_state.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Mostra tela de loading enquanto inicializa
    return MaterialApp(
      title: 'Iron Log',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: _buildHomeBasedOnAuth(authState),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildHomeBasedOnAuth(AuthState authState) {
    // Se ainda está carregando o estado inicial, mostra loading
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando autenticação...'),
            ],
          ),
        ),
      );
    }

    // Decide a rota inicial com base no estado
    final initialLocation = () {
      if (!authState.isLoggedIn) {
        print('🚪 Redirecionando para login - usuário não autenticado');
        return '/login';
      }
      if (!authState.onboardingCompleted) {
        print('📋 Redirecionando para onboarding');
        return '/onboarding';
      }
      print('🏠 Redirecionando para home - usuário autenticado');
      return '/home';
    }();

    return MaterialApp.router(
      title: 'Iron Log',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: createRouter(initialLocation),
      debugShowCheckedModeBanner: false,
    );
  }
}
