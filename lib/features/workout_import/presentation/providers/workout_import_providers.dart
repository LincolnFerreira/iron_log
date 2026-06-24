import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/providers/sync_providers.dart';
import 'package:iron_log/core/services/http_service.dart';

import '../../data/datasources/workout_import_local_datasource.dart';
import '../../data/datasources/workout_import_remote_datasource.dart';
import '../../data/repositories/workout_import_repository_impl.dart';
import '../../domain/repositories/workout_import_repository.dart';

final workoutImportLocalDataSourceProvider =
    Provider<WorkoutImportLocalDataSource>((ref) {
  return WorkoutImportLocalDataSource(ref.watch(driftDatabaseProvider));
});

final workoutImportRemoteDataSourceProvider =
    Provider<WorkoutImportRemoteDataSource>((ref) {
  return WorkoutImportRemoteDataSource(ref.watch(httpServiceProvider));
});

final workoutImportRepositoryProvider = Provider<WorkoutImportRepository>((ref) {
  return WorkoutImportRepositoryImpl(
    local: ref.watch(workoutImportLocalDataSourceProvider),
    remote: ref.watch(workoutImportRemoteDataSourceProvider),
  );
});

final workoutImportProvidersOverrides = <Override>[
  // Repository resolves via providers above; empty override list for API symmetry.
];
