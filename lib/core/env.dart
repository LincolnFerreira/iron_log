/// Environment configuration for API endpoints.
///
/// **Prod**: `flutter run --dart-define=FLAVOR=prod`
///
/// **Dev (emulador)**: default `10.0.2.2` — alias Android para localhost do host.
///
/// **Dev local (celular físico na Wi-Fi)**: passe o IP da máquina na LAN:
/// `flutter run --dart-define=FLAVOR=dev --dart-define=API_HOST=192.168.1.25`
/// ou use a config "Dev Local" em `.vscode/launch.json`.
class Env {
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// Host ou URL base para dev local (dispositivo físico na rede).
  /// Aceita `192.168.1.25` ou `http://192.168.1.25:3000`.
  static const String _apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );

  static const int _devPort = 3000;

  static String get apiBaseUrl {
    if (flavor == 'prod') {
      return 'https://iron-log-back-end.onrender.com';
    }

    if (_apiHost.isNotEmpty) {
      return _normalizeDevUrl(_apiHost);
    }

    // dev padrão — emulador Android → localhost da máquina host
    return 'http://10.0.2.2:$_devPort';
  }

  static String _normalizeDevUrl(String hostOrUrl) {
    if (hostOrUrl.startsWith('http://') || hostOrUrl.startsWith('https://')) {
      return hostOrUrl;
    }
    return 'http://$hostOrUrl:$_devPort';
  }
}
