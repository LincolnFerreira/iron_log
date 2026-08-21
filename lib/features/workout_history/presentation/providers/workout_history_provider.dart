import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import 'package:iron_log/features/workout_history/workout_history_providers.dart';

/// Provider que busca o histórico de treinos do usuário logado.
final workoutHistoryProvider = FutureProvider<List<WorkoutHistory>>((
  ref,
) async {
  return ref.read(workoutHistoryRepositoryProvider).getWorkoutHistory();
});
