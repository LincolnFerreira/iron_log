import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';

import '../models/workout_history_dto.dart';

class WorkoutHistoryMapper {
  const WorkoutHistoryMapper._();

  static WorkoutHistory fromDto(WorkoutHistoryDto dto) {
    final routineName = dto.routine?.name ?? 'Treino';

    final duration = dto.endedAt != null
        ? dto.endedAt!.difference(dto.startedAt)
        : Duration.zero;

    String? sessionName;
    String? sessionId;
    for (final serie in dto.series) {
      if (serie.sessionExercise?.session != null) {
        sessionName = serie.sessionExercise?.session?.name;
        sessionId = serie.sessionExercise?.session?.id;
        break;
      }
    }

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
            completedSeries: e.value,
          ),
        )
        .toList();

    final totalSeries = dto.series.length;

    return WorkoutHistory(
      id: dto.id,
      routineName: routineName,
      sessionName: sessionName,
      sessionId: sessionId,
      date: dto.startedAt,
      duration: duration,
      seriesCount: totalSeries,
      completedSeries: totalSeries,
      totalSeries: totalSeries,
      totalVolume: totalVolume,
      hasPR: false,
      exercises: exercises,
    );
  }
}
