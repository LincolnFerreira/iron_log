import '../../features/workout_day/domain/entities/workout_exercise.dart';
import '../../features/workout_day/data/models/session_exercise_dto.dart';
import '../../features/workout_day/data/models/serie_log_dto.dart';

/// Pragmatic mapper: delegates to DTO.toEntity() methods
/// Keeps logic where data lives, maintains type safety
class WorkoutDataMapper {
  /// Map from /session/:id response (SessionExercise array)
  static WorkoutExercise fromApiData(Map<String, dynamic> exerciseData) {
    return SessionExerciseDto.fromJson(exerciseData).toEntity();
  }

  /// Map list from /session/:id response
  static List<WorkoutExercise> fromApiList(List<dynamic> exercisesData) {
    return exercisesData
        .map((data) => fromApiData(data as Map<String, dynamic>))
        .toList();
  }

  /// Map from /workout/:id response (SerieLog flat array)
  /// Groups by exerciseId, converts each group to WorkoutExercise
  static List<WorkoutExercise> fromSerieLogList(List<dynamic> seriesRaw) {
    // Group by exerciseId while preserving order
    final grouped = <String, List<SerieLogDto>>{};

    for (final rawItem in seriesRaw) {
      final serie = SerieLogDto.fromJson(rawItem as Map<String, dynamic>);
      final exerciseId = serie.exerciseId ?? '';

      if (exerciseId.isNotEmpty) {
        grouped.putIfAbsent(exerciseId, () => []).add(serie);
      }
    }

    // Convert each group to WorkoutExercise
    return grouped.entries
        .map((entry) => SerieLogDto.groupToEntity(entry.key, entry.value))
        .toList();
  }
}
