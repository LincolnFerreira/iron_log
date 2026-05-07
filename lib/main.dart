import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/firebase_options.dart';
import 'app_widget.dart';
import 'core/services/auth_service.dart';
import 'features/routines/routine_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize GoogleSignIn on mobile only. Update `_webClientId` if needed.
  const String webClientId =
      '222174717889-qcdugbpqpmebh8j86q2t0rhfjqi48s64.apps.googleusercontent.com';
  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize(serverClientId: webClientId);
  }
  if (!kIsWeb) {
    // Envia erros do framework Flutter para o Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Captura erros fora do contexto do framework (isolates/event loop).
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Em debug local, evita "sujar" o dashboard; em release envia normalmente.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
  } else {
    // Crashlytics não possui suporte para Flutter Web.
    FlutterError.onError = FlutterError.dumpErrorToConsole;
  }

  // Inicializar AuthService
  AuthService().initialize();

  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            // Overrides para a feature de rotinas (deve ser aplicado ANTES de MyApp)
            ...routineProvidersOverrides,
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stackTrace) async {
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      } else {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      }
    },
  );
}
