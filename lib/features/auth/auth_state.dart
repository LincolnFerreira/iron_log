// features/auth/auth_state.dart
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/providers/user_profile_provider.dart';

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
  AuthNotifier(this._ref) : super(const AuthState()) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    print('🔄 Inicializando estado de autenticação...');

    // Carrega status do onboarding
    await loadOnboardingStatus();

    // Verifica estado atual imediatamente
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('🔐 Usuário já logado: ${currentUser.email}');
      state = state.copyWith(user: currentUser, isLoading: false);
    } else {
      print('🚪 Nenhum usuário logado');
      state = state.copyWith(user: null, isLoading: false);
    }

    // Observa mudanças de autenticação
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        print('🔐 Mudança de auth - Usuário logado: ${user.email}');
        print('🔑 Token/ID do usuário: ${user.uid}');
        user.getIdToken(true).then((token) {
          log('🔑 Token de autenticação: $token');
        });

        // Invalidar o provider do perfil para buscar os dados atualizados
        _ref.invalidate(userProfileProvider);
      } else {
        print('🚪 Mudança de auth - Usuário não está logado');
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
  return AuthNotifier(ref);
});
