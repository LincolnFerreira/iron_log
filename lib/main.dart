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
import 'core/observability/crash_reporting_service.dart';
import 'core/services/auth_service.dart';
import 'core/widgets/app_error_fallback.dart';
import 'features/routines/routine_providers.dart';

late final CrashReportingService _crashReportingService;

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _crashReportingService = CrashReportingService();

      const String webClientId =
          '222174717889-qcdugbpqpmebh8j86q2t0rhfjqi48s64.apps.googleusercontent.com';
      if (!kIsWeb) {
        await GoogleSignIn.instance.initialize(serverClientId: webClientId);
      }

      if (!kIsWeb) {
        FlutterError.onError = (details) {
          _crashReportingService.recordFlutterFatal(details);
          if (kDebugMode) {
            FlutterError.presentError(details);
          }
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          _crashReportingService.recordFatal(error, stack);
          return true;
        };

        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          !kDebugMode,
        );
      } else {
        FlutterError.onError = FlutterError.dumpErrorToConsole;
      }

      ErrorWidget.builder = (details) {
        return AppErrorFallback(
          details: details,
          crashReporting: kIsWeb ? null : _crashReportingService,
        );
      };

      AuthService().initialize();

      runApp(
        ProviderScope(
          overrides: [...routineProvidersOverrides],
          child: const MyApp(),
        ),
      );
    },
    (error, stackTrace) async {
      if (!kIsWeb) {
        await _crashReportingService.recordFatal(error, stackTrace);
      } else {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      }
    },
  );
}
