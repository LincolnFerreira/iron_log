/// Environment configuration for API endpoints.
/// Use `flutter run --dart-define=FLAVOR=prod` or
/// `flutter build ... --dart-define=FLAVOR=prod` to switch to production.
class Env {
  // Read the FLAVOR from compile-time environment; default to 'dev'.
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static String get apiBaseUrl {
    if (flavor == 'prod') {
      return 'https://iron-log-back-end.onrender.com';
    }
    // Default (dev) — Android emulator alias for host localhost
    return 'http://10.0.2.2:3000';
  }
}
