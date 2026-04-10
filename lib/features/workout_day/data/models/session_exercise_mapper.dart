import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

import 'exercise_tag_mapper.dart';
import 'series_entry_mapper.dart';
import 'series_summary_extractor.dart';
import 'session_exercise_dto.dart';

/// Maps [SessionExerciseDto] (from /session/:id) to [WorkoutExercise]
class SessionExerciseMapper {
  /// Convert a single SessionExerciseDto to WorkoutExercise
  static WorkoutExercise map(SessionExerciseDto dto) {
    final entries = SeriesEntryMapper.listFromConfig(dto.config.series);
    final summary = SeriesSummaryExtractor.fromConfigList(dto.config.series);

    final weight = (summary['weight'] as double?) ?? 0.0;
    final weightString = weight > 0 ? '${weight}kg' : '0kg';
    final reps = (summary['reps'] as int?) ?? 0;

    return WorkoutExercise(
      id: dto.exerciseId ?? '',
      name: dto.exercise.name ?? '',
      tag: ExerciseTagMapper.map(dto.exercise),
      muscles: dto.exercise.primaryMuscle ?? 'Não especificado',
      variation: dto.config.variation ?? 'Traditional',
      series: dto.config.series.isNotEmpty ? dto.config.series.length : 3,
      reps: reps > 0 ? reps.toString() : '-',
      weight: weightString,
      rir: (summary['rir'] as int?) ?? 0,
      restTime: (summary['restTime'] as int?) ?? 0,
      entries: entries,
    );
  }

  /// Convert multiple SessionExerciseDtos to WorkoutExercises
  static List<WorkoutExercise> mapList(List<SessionExerciseDto> dtos) {
    return dtos.map(map).toList();
  }

  /// Parse raw API data to SessionExerciseDto first, then map
  static WorkoutExercise mapFromJson(Map<String, dynamic> json) {
    final dto = SessionExerciseDto.fromJson(json);
    return map(dto);
  }

  /// Parse and map multiple raw API items
  static List<WorkoutExercise> mapFromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => mapFromJson(item as Map<String, dynamic>))
        .toList();
  }
}
