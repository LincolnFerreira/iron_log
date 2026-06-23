import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:iron_log/core/observability/crash_reporting_service.dart';
import 'package:iron_log/core/services/firebase_auth_token.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_state.dart';
import 'presentation/providers/user_profile_provider.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  final CrashReportingService _crashReporting = CrashReportingService();

  @override
  AuthState build() {
    Future.microtask(_init);
    final subscription = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthChanged,
    );
    ref.onDispose(subscription.cancel);
    return const AuthState();
  }

  Future<void> _init() async {
    if (kDebugMode) {
      debugPrint('🔄 Inicializando estado de autenticação...');
    }

    await loadOnboardingStatus();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (kDebugMode) {
        debugPrint('🔐 Usuário já logado: ${currentUser.email}');
      }
      state = state.copyWith(user: currentUser, isLoading: false);
      unawaited(_crashReporting.setUserContext(currentUser.uid));
    } else {
      if (kDebugMode) {
        debugPrint('🚪 Nenhum usuário logado');
      }
      state = state.copyWith(user: null, isLoading: false);
    }
  }

  void _onAuthChanged(User? user) {
    if (user != null) {
      if (kDebugMode) {
        debugPrint('🔐 Mudança de auth - Usuário logado: ${user.email}');
        debugPrint('🔑 UID: ${user.uid}');
      }
      unawaited(_crashReporting.setUserContext(user.uid));
      if (kDebugMode) {
        safeGetIdToken(user).then((token) {
          if (token != null) {
            debugPrint('🔑 Token (cache) length: ${token.length}');
          } else {
            debugPrint(
              '🔑 Token indisponível (rede/offline), sessão local mantida',
            );
          }
        });
      }
      ref.invalidate(userProfileProvider);
    } else {
      if (kDebugMode) {
        debugPrint('🚪 Mudança de auth - Usuário não está logado');
      }
      unawaited(_crashReporting.setUserContext(null));
    }

    state = state.copyWith(user: user, isLoading: false);
  }

  Future<void> signOut() async {
    state = state.copyWith(user: null, isLoading: false);
    unawaited(_crashReporting.setUserContext(null));
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
    state = state.copyWith(onboardingCompleted: true);
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
  }
}

/// Alias de compatibilidade — preferir [authControllerProvider] em código novo.
final authStateProvider = authControllerProvider;
