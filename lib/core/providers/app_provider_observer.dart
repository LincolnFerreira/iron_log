import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/debug/diag_log.dart';

/// Logs provider lifecycle in debug builds to trace state/DI during development.
class AppProviderObserver extends ProviderObserver {
  String _name(ProviderBase<Object?> provider) =>
      provider.name ?? provider.runtimeType.toString();

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    DiagLog.provider('created', detail: _name(provider));
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    DiagLog.provider('disposed', detail: _name(provider));
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    DiagLog.provider('updated', detail: '${_name(provider)} → $newValue');
  }
}
