import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_widget.dart';
import 'core/services/auth_service.dart';
import 'features/routines/routine_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
