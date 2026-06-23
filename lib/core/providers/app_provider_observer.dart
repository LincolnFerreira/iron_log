import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logs provider updates in debug builds to trace state/DI during development.
class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    final providerName = provider.name ?? provider.runtimeType;
    debugPrint('Provider $providerName -> $newValue');
  }
}
