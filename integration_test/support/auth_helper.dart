import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/auth/presentation/auth_test_keys.dart';
import 'package:iron_log/features/auth/presentation/pages/login_screen.dart';
import 'package:iron_log/firebase_options.dart';
import 'package:patrol/patrol.dart';

/// Conta Google do emulador — opcional; senão usa a 1ª conta listada no picker.
const _kGoogleAccountHint = String.fromEnvironment('E2E_GOOGLE_ACCOUNT');

const _kGoogleWebClientId =
    '222174717889-qcdugbpqpmebh8j86q2t0rhfjqi48s64.apps.googleusercontent.com';

class E2eAuthHelper {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AuthService().initialize();
    HttpService().initialize();
    if (!kIsWeb) {
      await GoogleSignIn.instance.initialize(serverClientId: _kGoogleWebClientId);
    }
  }

  /// Login via UI + picker nativo do Google (Patrol).
  static Future<void> ensureAuthenticated(PatrolIntegrationTester $) async {
    await initialize();

    if (FirebaseAuth.instance.currentUser != null) return;

    final silent = await _tryGoogleSilentSignIn();
    if (silent != null) return;

    await _signInWithGooglePatrol($);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(
        'Login Google falhou. Confira conta no emulador ou passe '
        '--dart-define=E2E_GOOGLE_ACCOUNT=seu@gmail.com',
      );
    }
  }

  static Future<User?> _tryGoogleSilentSignIn() async {
    if (kIsWeb) return null;
    try {
      final attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
      GoogleSignInAccount? account;
      if (attempt != null) account = await attempt;
      if (account == null) {
        try {
          account = await GoogleSignIn.instance.authenticate();
        } catch (_) {
          account = null;
        }
      }
      if (account == null) return null;

      final idToken = account.authentication.idToken;
      if (idToken == null) return null;

      final result = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return result.user;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _signInWithGooglePatrol(PatrolIntegrationTester $) async {
    await $.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
    await $.pumpAndSettle();

    await $(AuthTestKeys.googleSignIn).tap();

    // Picker / OAuth rodam fora do Flutter — Patrol interage nativamente.
    await Future<void>.delayed(const Duration(seconds: 2));
    await _selectGoogleAccount($);

    // Aguarda Firebase propagar sessão após OAuth.
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      if (FirebaseAuth.instance.currentUser != null) return;
      await $.pump(const Duration(milliseconds: 500));
    }
  }

  static Future<void> _selectGoogleAccount(PatrolIntegrationTester $) async {
    const timeout = Duration(seconds: 20);

    if (_kGoogleAccountHint.isNotEmpty) {
      await $.platform.tap(
        Selector(textContains: _kGoogleAccountHint),
        timeout: timeout,
      );
      await _confirmGoogleOAuth($);
      return;
    }

    // Picker nativo Google — 1ª conta listada (Stack Overflow / Patrol pattern).
    try {
      await $.platform.tap(
        Selector(
          textContains: '@',
          instance: 0,
          pkg: 'com.google.android.gms',
        ),
        timeout: timeout,
      );
    } catch (_) {
      await $.platform.tap(
        Selector(textContains: '@', instance: 0),
        timeout: timeout,
      );
    }

    await _confirmGoogleOAuth($);
  }

  static Future<void> _confirmGoogleOAuth(PatrolIntegrationTester $) async {
    for (final label in ['Continuar', 'Continue', 'Allow', 'Permitir']) {
      try {
        await $.platform.tap(
          Selector(text: label),
          timeout: const Duration(seconds: 4),
        );
        return;
      } catch (_) {}
    }
  }
}
