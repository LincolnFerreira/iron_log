/// Environment configuration for API endpoints.
///
/// **Cloud**: `--dart-define=FLAVOR=prod` → Render.
///
/// **Local API**: `--dart-define=FLAVOR=dev` → `http://127.0.0.1:3000`
/// (celular/emulador com `adb reverse tcp:3000 tcp:3000` — launch Local API).
///
/// **Wi‑Fi (celular físico)**: copie `dart_defines.dev.example.json` →
/// `dart_defines.dev.json`, fixe o IP no roteador (reserva DHCP) e use
/// `--dart-define-from-file=dart_defines.dev.json` no launch.
///
/// **Escape hatch**: `--dart-define=API_HOST=<ip>` pontual.
class Env {
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

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

    return 'http://127.0.0.1:$_devPort';
  }

  static String _normalizeDevUrl(String hostOrUrl) {
    if (hostOrUrl.startsWith('http://') || hostOrUrl.startsWith('https://')) {
      return hostOrUrl;
    }
    return 'http://$hostOrUrl:$_devPort';
  }
}
