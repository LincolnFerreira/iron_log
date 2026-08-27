import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:iron_log/core/observability/crash_reporting_service.dart';
import 'package:iron_log/core/services/firebase_auth_token.dart';
import 'package:iron_log/core/services/google_auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_state.dart';
import 'user_profile_provider.dart';
import 'package:iron_log/features/auth/auth_providers.dart';

part 'auth_controller.g.dart';

/// Web OAuth client ID (Google Cloud / Firebase) for Android Google Sign-In.
const _googleServerClientId =
    '222174717889-qcdugbpqpmebh8j86q2t0rhfjqi48s64.apps.googleusercontent.com';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  final CrashReportingService _crashReporting = CrashReportingService();
  final GoogleAuthService _googleAuth = GoogleAuthService();
  bool _debugTokenLogged = false;

  void _maybeLogDebugToken(User user) {
    if (!kDebugMode || _debugTokenLogged) return;
    _debugTokenLogged = true;
    unawaited(debugLogIdToken(user));
  }

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
      _maybeLogDebugToken(currentUser);
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
      _maybeLogDebugToken(user);
      ref.invalidate(userProfileProvider);
    } else {
      _debugTokenLogged = false;
      if (kDebugMode) {
        debugPrint('🚪 Mudança de auth - Usuário não está logado');
      }
      unawaited(_crashReporting.setUserContext(null));
    }

    state = state.copyWith(user: user, isLoading: false);
  }

  void clearFeedback() {
    if (state.feedback != null) {
      state = state.copyWith(feedback: null);
    }
  }

  Future<void> syncBackendUser(User user) async {
    try {
      await ref.read(authRepositoryProvider).upsertUser(
        firebaseId: user.uid,
        email: user.email ?? '',
        name: user.displayName,
      );
      state = state.copyWith(
        feedback: AuthFeedback.success(
          title: 'Sucesso',
          message: 'Usuário sincronizado com o servidor',
        ),
      );
    } catch (e) {
      state = state.copyWith(
        feedback: AuthFeedback.warning(
          title: 'Sincronização',
          message: 'Erro ao sincronizar usuário: $e',
        ),
      );
    }
  }

  /// Google Sign-In + retorno do [User] Firebase. `null` se cancelar ou falhar.
  Future<User?> signInWithGoogle() async {
    state = state.copyWith(isSigningIn: true, feedback: null);
    try {
      final result = await _googleAuth.signInWithGoogle(
        serverClientId: _googleServerClientId,
      );
      if (result == null) {
        state = state.copyWith(isSigningIn: false);
        return null;
      }
      final user = result.user ?? FirebaseAuth.instance.currentUser;
      state = state.copyWith(isSigningIn: false);
      return user;
    } catch (e) {
      state = state.copyWith(
        isSigningIn: false,
        feedback: AuthFeedback.error(
          title: 'Erro no login',
          message: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<void> signOut() async {
    _debugTokenLogged = false;
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
