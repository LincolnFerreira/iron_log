import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/providers/sync_providers.dart';
import 'package:iron_log/core/services/http_service.dart';

import '../auth/auth_state.dart';
import 'data/datasources/routine_local_datasource.dart';
import 'data/datasources/routine_remote_datasource.dart';
import 'data/repositories/routine_cached_repository_impl.dart';
import 'domain/repositories/routine_repository.dart';
import 'presentation/bloc/routine_provider.dart';

/// HTTP-only routine API (sem cache). Consumido pelo repositório com cache local.
final routineRemoteDataSourceProvider = Provider<RoutineRemoteDataSource>((ref) {
  final httpService = ref.watch(httpServiceProvider);
  return RoutineRemoteDataSourceImpl(httpService.dio);
});

/// Repositório de rotinas: cache Drift + rede via [RoutineRemoteDataSource].
final routineRepositoryProviderImpl = Provider<RoutineRepository>((ref) {
  try {
    final remote = ref.watch(routineRemoteDataSourceProvider);
    final database = ref.watch(driftDatabaseProvider);
    final connectivity = ref.watch(connectivityProvider);
    final userId = ref.watch(authStateProvider).user?.uid ?? '';

    final localDataSource = RoutineLocalDataSourceImpl(database: database);

    return RoutineCachedRepositoryImpl(
      remote: remote,
      localDataSource: localDataSource,
      connectivity: connectivity,
      userId: userId,
    );
  } catch (e) {
    throw StateError(
      'Failed to create RoutineRepository: $e. '
      'Ensure HttpService and Drift database are properly initialized.',
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
