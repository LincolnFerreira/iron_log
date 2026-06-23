import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';

import '../../data/datasources/workout_history_remote_datasource.dart';
import '../../data/repositories/workout_history_repository_impl.dart';
import '../../domain/repositories/workout_history_repository.dart';

final workoutHistoryRemoteDataSourceProvider =
    Provider<WorkoutHistoryRemoteDataSource>((ref) {
      final httpService = ref.read(httpServiceProvider);
      return WorkoutHistoryRemoteDataSourceImpl(httpService.dio);
    });

final workoutHistoryRepositoryProvider = Provider<WorkoutHistoryRepository>((
  ref,
) {
  final remote = ref.read(workoutHistoryRemoteDataSourceProvider);
  return WorkoutHistoryRepositoryImpl(remote: remote);
});

/// Provider que busca o histórico de treinos do usuário logado.
final workoutHistoryProvider = FutureProvider<List<WorkoutHistory>>((
  ref,
) async {
  final repository = ref.read(workoutHistoryRepositoryProvider);
  return repository.getWorkoutHistory();
});
