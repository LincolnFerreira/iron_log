import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/workout_history/data/datasources/workout_history_remote_datasource.dart';
import 'package:iron_log/features/workout_history/data/repositories/workout_history_repository_impl.dart';
import 'package:iron_log/features/workout_history/domain/repositories/workout_history_repository.dart';

/// Abstract history repository — MUST be overridden at app startup.
final workoutHistoryRepositoryProvider = Provider<WorkoutHistoryRepository>((
  ref,
) {
  throw UnimplementedError(
    'workoutHistoryRepositoryProvider must be overridden. '
    'Apply workoutHistoryProvidersOverrides in ProviderScope.',
  );
});

final workoutHistoryRemoteDataSourceProvider =
    Provider<WorkoutHistoryRemoteDataSource>((ref) {
      return WorkoutHistoryRemoteDataSourceImpl(
        ref.read(httpServiceProvider).dio,
      );
    });

final workoutHistoryRepositoryProviderImpl =
    Provider<WorkoutHistoryRepository>((ref) {
      return WorkoutHistoryRepositoryImpl(
        remote: ref.read(workoutHistoryRemoteDataSourceProvider),
      );
    });

final workoutHistoryRepositoryOverride =
    workoutHistoryRepositoryProvider.overrideWith(
      (ref) => ref.read(workoutHistoryRepositoryProviderImpl),
    );

final workoutHistoryProvidersOverrides = [workoutHistoryRepositoryOverride];
