import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/database/app_database.dart';
import 'data/datasources/routine_local_datasource.dart';
import 'data/repositories/routine_repository_offline_impl.dart';
import 'domain/repositories/routine_repository.dart';
import 'presentation/bloc/routine_provider.dart';

/// Provider para o repositório com suporte offline usando Drift + Dio
final routineRepositoryProviderImpl = Provider<RoutineRepository>((ref) {
  try {
    final httpService = ref.watch(httpServiceProvider);
    final database = ref.watch(_driftDatabaseProvider);
    final connectivity = Connectivity();

    // TODO: Get userId from auth provider when available
    // For now, using placeholder - will be updated in Phase 1.2
    const userId = 'current-user-id';

    final localDataSource = RoutineLocalDataSourceImpl(database: database);

    return RoutineRepositoryOfflineImpl(
      dio: httpService.dio,
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

// ============ Internal Providers ============

/// Internal Drift database provider
final _driftDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
