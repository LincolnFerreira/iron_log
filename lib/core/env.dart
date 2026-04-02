/// Environment configuration for API endpoints.
/// Use `flutter run --dart-define=FLAVOR=prod` or
/// `flutter build ... --dart-define=FLAVOR=prod` to switch to production.
class Env {
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  // Host configurável para o flavor local (dispositivo físico na rede local).
  static const String _apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (flavor == 'prod') {
      return 'https://iron-log-back-end.onrender.com';
    }

    // dev — alias do emulador Android para o localhost da máquina host
    return 'http://10.0.2.2:3000';
  }
}
