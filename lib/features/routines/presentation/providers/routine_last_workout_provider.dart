import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import 'package:iron_log/features/workout_history/data/models/workout_history_dto.dart';

/// Busca o último treino registrado de uma rotina específica.
/// Retorna null se nenhum treino existir para essa rotina.
final routineLastWorkoutProvider =
    FutureProvider.family<WorkoutHistory?, String>((ref, routineId) async {
      final http = ref.watch(httpServiceProvider);

      try {
        final response = await http.get(
          '/routine/$routineId/workouts',
          queryParameters: {'take': 1},
        );
        final List<dynamic> data = response.data as List<dynamic>;
        if (data.isEmpty) return null;

        final dto = WorkoutHistoryDto.fromJson(
          data.first as Map<String, dynamic>,
        );

        final routineName = dto.routine?.name ?? 'Treino';

        final duration = dto.endedAt != null
            ? dto.endedAt!.difference(dto.startedAt)
            : Duration.zero;

        final Map<String, int> exerciseCount = {};
        double totalVolume = 0;

        for (final serie in dto.series) {
          exerciseCount[serie.exercise.name] =
              (exerciseCount[serie.exercise.name] ?? 0) + 1;
          totalVolume += serie.weight * serie.reps;
        }

        final exercises = exerciseCount.entries
            .map(
              (e) => WorkoutHistoryExercise(
                exerciseName: e.key,
                seriesCount: e.value,
                completedSeries: e.value,
              ),
            )
            .toList();

        return WorkoutHistory(
          id: dto.id,
          routineName: routineName,
          sessionName: null,
          date: dto.startedAt,
          duration: duration,
          seriesCount: dto.series.length,
          completedSeries: dto.series.length,
          totalSeries: dto.series.length,
          totalVolume: totalVolume,
          hasPR: false,
          exercises: exercises,
        );
      } catch (_) {
        return null;
      }
    });
