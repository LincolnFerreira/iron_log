import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Wrapper Firebase Crashlytics com no-op em debug/web.
class CrashReportingService {
  CrashReportingService._({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics;

  factory CrashReportingService({FirebaseCrashlytics? crashlytics}) {
    return CrashReportingService._(
      crashlytics: crashlytics ?? FirebaseCrashlytics.instance,
    );
  }

  /// Sem Firebase — útil em testes unitários.
  factory CrashReportingService.noop() => CrashReportingService._();

  final FirebaseCrashlytics? _crashlytics;

  FirebaseCrashlytics? get _activeCrashlytics {
    if (_crashlytics == null || kIsWeb || kDebugMode) return null;
    return _crashlytics;
  }

  Future<void> recordWidgetError(FlutterErrorDetails details) async {
    final crashlytics = _activeCrashlytics;
    if (crashlytics == null) return;

    await crashlytics.setCustomKey('error_source', 'widget_build');
    await crashlytics.recordFlutterError(details);
  }

  Future<void> setUserContext(String? firebaseUid) async {
    final crashlytics = _activeCrashlytics;
    if (crashlytics == null) return;

    if (firebaseUid == null || firebaseUid.isEmpty) {
      await crashlytics.setUserIdentifier('');
      return;
    }
    final opaque = firebaseUid.length <= 12
        ? firebaseUid
        : firebaseUid.substring(firebaseUid.length - 12);
    await crashlytics.setUserIdentifier('u_$opaque');
  }

  Future<void> recordFlutterFatal(FlutterErrorDetails details) async {
    final crashlytics = _activeCrashlytics;
    if (crashlytics == null) return;
    await crashlytics.recordFlutterFatalError(details);
  }

  Future<void> recordFatal(Object error, StackTrace stack) async {
    final crashlytics = _activeCrashlytics;
    if (crashlytics == null) return;
    await crashlytics.recordError(error, stack, fatal: true);
  }
}
