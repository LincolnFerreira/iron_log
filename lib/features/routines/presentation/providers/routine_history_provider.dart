import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/core/services/http_service.dart';

/// Provider que busca o histórico de treinos de uma rotina no backend.
final routineHistoryProvider =
    FutureProvider.family<List<WorkoutExercise>, String>((
      ref,
      routineId,
    ) async {
      final httpService = ref.watch(httpServiceProvider);

      try {
        final response = await httpService.get(
          '/routine/$routineId/workouts',
          queryParameters: {'take': 3},
        );
        final List<dynamic> data = response.data as List<dynamic>;

        // Flatten latest workouts into a list of WorkoutExercise summaries.
        final Map<String, WorkoutExercise> byExercise = {};

        for (final workout in data) {
          final series = (workout['series'] as List<dynamic>?) ?? [];
          for (final s in series) {
            final ex = s['exercise'] as Map<String, dynamic>?;
            if (ex == null) continue;
            final exId = ex['id']?.toString() ?? '';
            final exName = ex['name']?.toString() ?? 'Exercício';

            if (!byExercise.containsKey(exId)) {
              byExercise[exId] = WorkoutExercise(
                id: exId,
                name: exName,
                tag: ExerciseTag.multi, // TODO: map real tag when available
                muscles: '',
                variation: '',
                series: 0,
                reps: '-',
                weight: '0kg',
                rir: 2,
                restTime: 60,
              );
            }

            // Increment series count
            final existing = byExercise[exId]!;
            byExercise[exId] = existing.copyWith(series: existing.series + 1);
          }
        }

        return byExercise.values.toList();
      } catch (e) {
        // Fallback para uma lista vazia em caso de erro
        return [];
      }
    });
