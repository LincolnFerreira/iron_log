import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import 'package:iron_log/features/workout_history/presentation/providers/workout_history_provider.dart';

/// Último treino registrado de uma rotina (null se inexistente ou erro de rede).
final routineLastWorkoutProvider =
    FutureProvider.family<WorkoutHistory?, String>((ref, routineId) async {
      final repository = ref.read(workoutHistoryRepositoryProvider);
      return repository.getLastWorkoutForRoutine(routineId);
    });
