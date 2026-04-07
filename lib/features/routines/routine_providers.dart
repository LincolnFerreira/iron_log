import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'data/repositories/routine_repository_impl.dart';
import 'domain/repositories/routine_repository.dart';
import 'presentation/bloc/routine_provider.dart';

/// Provider para o repositório usando HttpService unificado
final routineRepositoryProviderImpl = Provider<RoutineRepository>((ref) {
  try {
    final httpService = ref.watch(httpServiceProvider);
    return RoutineRepositoryImpl(httpService.dio);
  } catch (e) {
    throw StateError(
      'Failed to create RoutineRepository: $e. '
      'Ensure HttpService provider is properly initialized.',
    );
  }
});

/// Override do provider abstrato - MUST be applied in ProviderScope at app startup
final routineRepositoryOverride = routineRepositoryProvider.overrideWith(
  (ref) => ref.watch(routineRepositoryProviderImpl),
);

/// Lista de overrides para configurar os providers em main.dart
/// Usage in main.dart:
///   ProviderScope(
///     overrides: [...routineProvidersOverrides],
///     child: const MyApp(),
///   )
final routineProvidersOverrides = [routineRepositoryOverride];
