// features/auth/auth_state.dart
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final User? user;
  final bool onboardingCompleted;
  final bool isLoading;

  const AuthState({
    this.user,
    this.onboardingCompleted = false,
    this.isLoading = true,
  });

  AuthState copyWith({User? user, bool? onboardingCompleted, bool? isLoading}) {
    return AuthState(
      user: user ?? this.user,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isLoggedIn => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    print('🔄 Inicializando estado de autenticação...');

    // Carrega status do onboarding
    await loadOnboardingStatus();

    // Observa mudanças de autenticação
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        print('🔐 Usuário logado: ${user.email}');
        print('🔑 Token/ID do usuário: ${user.uid}');
        user.getIdToken(true).then((token) {
          log('🔑 Token de autenticação: $token');
        });
      } else {
        print('🚪 Usuário não está logado');
      }

      state = state.copyWith(user: user, isLoading: false);
    });
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> loadOnboardingStatus() async {
    // Implemente sua lógica de carregamento aqui
    // Exemplo com SharedPreferences:
    // final prefs = await SharedPreferences.getInstance();
    // _onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
    state = state.copyWith(
      onboardingCompleted: true,
    ); // Valor padrão temporário
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
    // Persistir no SharedPreferences se necessário
    // await prefs.setBool('onboardingCompleted', true);
  }
}

// Provider global para o AuthState
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
