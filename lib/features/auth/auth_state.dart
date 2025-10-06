// features/auth/auth_state.dart
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState extends ChangeNotifier {
  User? _user;
  bool _onboardingCompleted = false;
  bool _isLoading = true; // Estado inicial de loading

  AuthState() {
    _init();
  }

  Future<void> _init() async {
    print('🔄 Inicializando estado de autenticação...');

    // Carrega status do onboarding
    await loadOnboardingStatus();

    // Observa mudanças de autenticação
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      _isLoading = false; // Terminou de carregar

      if (user != null) {
        print('🔐 Usuário logado: ${user.email}');
        print('🔑 Token/ID do usuário: ${user.uid}');
        user.getIdToken(true).then((token) {
          log('🔑 Token de autenticação: $token');
        });
      } else {
        print('🚪 Usuário não está logado');
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get isLoading => _isLoading;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> loadOnboardingStatus() async {
    // Implemente sua lógica de carregamento aqui
    // Exemplo com SharedPreferences:
    // final prefs = await SharedPreferences.getInstance();
    // _onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
    _onboardingCompleted = true; // Valor padrão temporário
  }

  void completeOnboarding() {
    _onboardingCompleted = true;
    // Persistir no SharedPreferences se necessário
    // await prefs.setBool('onboardingCompleted', true);
    notifyListeners();
  }
}

// Provider global para o AuthState
final authStateProvider = ChangeNotifierProvider<AuthState>((ref) {
  return AuthState();
});
