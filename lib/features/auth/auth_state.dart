// features/auth/auth_state.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/firebase_auth_token.dart';
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

  static const _noUserChange = Object();

  AuthState copyWith({
    Object? user = _noUserChange,
    bool? onboardingCompleted,
    bool? isLoading,
  }) {
    return AuthState(
      user: identical(user, _noUserChange) ? this.user : user as User?,
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
        print('🔑 UID: ${user.uid}');
        // Nunca use getIdToken(true) aqui: força rede e estoura offline
        // (`network-request-failed`). Perfil/API usam safeGetIdToken no interceptor.
        if (kDebugMode) {
          safeGetIdToken(user).then((token) {
            if (token != null) {
              debugPrint('🔑 Token (cache) length: ${token.length}');
            } else {
              debugPrint('🔑 Token indisponível (rede/offline), sessão local mantida');
            }
          });
        }

        _ref.invalidate(userProfileProvider);
      } else {
        print('🚪 Mudança de auth - Usuário não está logado');
      }

      state = state.copyWith(user: user, isLoading: false);
    });
  }

  Future<void> signOut() async {
    // Atualiza estado localmente de forma otimista para evitar que o
    // router leia um estado ainda inconsistente enquanto o signOut
    // do Firebase está sendo processado.
    state = state.copyWith(user: null, isLoading: false);
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      if (isFirebaseAuthNetworkFailure(e)) {
        return;
      }
      rethrow;
    }
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
