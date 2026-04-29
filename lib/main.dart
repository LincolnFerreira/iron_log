import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Inicializar AuthService
  AuthService().initialize();

  runApp(
    ProviderScope(
      overrides: [
        // Overrides para a feature de rotinas (deve ser aplicado ANTES de MyApp)
        ...routineProvidersOverrides,
      ],
      child: const MyApp(),
    ),
  );
}
