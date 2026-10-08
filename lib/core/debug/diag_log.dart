import 'package:flutter/foundation.dart';

/// Temporary lifecycle / state / HTTP diagnostics (debug only).
///
/// Search for `[DIAG:` to remove or consolidate after investigation.
abstract final class DiagLog {
  static const _prefix = '[DIAG';

  static void lifecycle(String event, {String? detail}) {
    _print('lifecycle', event, detail);
  }

  static void widget(String event, {String? detail}) {
    _print('widget', event, detail);
  }

  static void provider(String event, {String? detail}) {
    _print('provider', event, detail);
  }

  static void http(String event, {String? detail}) {
    _print('http', event, detail);
  }

  static void connectivity(String event, {String? detail}) {
    _print('connectivity', event, detail);
  }

  static void _print(String channel, String event, String? detail) {
    if (!kDebugMode) return;
    final suffix = detail == null || detail.isEmpty ? '' : ' | $detail';
    debugPrint('$_prefix:$channel] $event$suffix');
  }
}
