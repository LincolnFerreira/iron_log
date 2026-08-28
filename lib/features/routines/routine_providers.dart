import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/providers/sync_providers.dart';
import 'package:iron_log/core/services/http_service.dart';

import 'package:iron_log/features/auth/auth.dart';
import 'package:iron_log/features/routines/data/datasources/exercise_remote_datasource.dart';
import 'package:iron_log/features/routines/data/datasources/routine_local_datasource.dart';
import 'package:iron_log/features/routines/data/datasources/routine_remote_datasource.dart';
import 'package:iron_log/features/routines/data/repositories/routine_cached_repository_impl.dart';
import 'package:iron_log/features/routines/domain/repositories/routine_repository.dart';
import 'package:iron_log/features/routines/presentation/providers/routine_provider.dart';

/// HTTP-only routine API (sem cache). Consumido pelo repositório com cache local.
final routineRemoteDataSourceProvider = Provider<RoutineRemoteDataSource>((ref) {
  final httpService = ref.read(httpServiceProvider);
  return RoutineRemoteDataSourceImpl(httpService.dio);
});

final exerciseRemoteDataSourceProvider = Provider<ExerciseRemoteDataSource>((
  ref,
) {
  return ExerciseRemoteDataSource(ref.read(httpServiceProvider));
});

/// Repositório de rotinas: cache Drift + rede via [RoutineRemoteDataSource].
final routineRepositoryProviderImpl = Provider<RoutineRepository>((ref) {
  try {
    // userId é dependência reativa (login); infra DI usa read (T074).
    final userId = ref.watch(
      authStateProvider.select((s) => s.user?.uid ?? ''),
    );
    final remote = ref.read(routineRemoteDataSourceProvider);
    final database = ref.read(driftDatabaseProvider);
    final connectivity = ref.read(connectivityProvider);

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
  (ref) => ref.read(routineRepositoryProviderImpl),
);

/// Lista de overrides para configurar os providers em main.dart
final routineProvidersOverrides = [routineRepositoryOverride];
