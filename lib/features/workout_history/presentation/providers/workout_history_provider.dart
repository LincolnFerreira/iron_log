import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import 'package:iron_log/features/workout_history/data/models/workout_history_dto.dart';

/// Provider que busca o histórico de treinos do usuário logado.
final workoutHistoryProvider = FutureProvider<List<WorkoutHistory>>((
  ref,
) async {
  final auth = AuthService();
  final response = await auth.get(ApiEndpoints.workouts);
  final list = (response.data as List<dynamic>? ?? []);
  return list.map((item) {
    final dto = WorkoutHistoryDto.fromJson(item as Map<String, dynamic>);

    final routineName = dto.routine?.name ?? 'Treino';

    final duration = dto.endedAt != null
        ? dto.endedAt!.difference(dto.startedAt)
        : Duration.zero;

    // Extract sessionName and sessionId from the first serie that carries session info
    String? sessionName;
    String? sessionId;
    for (final serie in dto.series) {
      if (serie.sessionExercise?.session != null) {
        sessionName = serie.sessionExercise?.session?.name;
        sessionId = serie.sessionExercise?.session?.id;
        break;
      }
    }

    // Group series by exercise name to build WorkoutHistoryExercise list
    final Map<String, int> exerciseSeriesCount = {};
    double totalVolume = 0;
    for (final serie in dto.series) {
      exerciseSeriesCount[serie.exercise.name] =
          (exerciseSeriesCount[serie.exercise.name] ?? 0) + 1;
      totalVolume += serie.weight * serie.reps;
    }

    final exercises = exerciseSeriesCount.entries
        .map(
          (e) => WorkoutHistoryExercise(
            exerciseName: e.key,
            seriesCount: e.value,
            completedSeries: e.value, // all saved series are completed
          ),
        )
        .toList();

    final totalSeries = dto.series.length;
    final completedSeries = totalSeries; // all saved series are completed

    // TODO: map hasPR when the API supports personal record detection
    return WorkoutHistory(
      id: dto.id,
      routineName: routineName,
      sessionName: sessionName,
      sessionId: sessionId,
      date: dto.startedAt,
      duration: duration,
      seriesCount: totalSeries,
      completedSeries: completedSeries,
      totalSeries: totalSeries,
      totalVolume: totalVolume,
      hasPR: false,
      exercises: exercises,
    );
  }).toList();
});
