import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

import 'series_entry_mapper.dart';
import 'series_summary_extractor.dart';
import 'serie_log_dto.dart';
import 'serie_log_grouper.dart';

/// Maps grouped [SerieLogDto] (from /workout/:id) to [WorkoutExercise]
class SerieLogUnitMapper {
  /// Convert a group of SerieLogDtos for one exercise to WorkoutExercise
  static WorkoutExercise map(
    String exerciseId,
    List<SerieLogDto> series,
    ExerciseMetadata meta,
  ) {
    // Build entries from each executed set
    final entries = SeriesEntryMapper.listFromSerieLog(series);

    // Extract summary from first set
    final summary = SeriesSummaryExtractor.fromSerieLogList(series);

    final weight = (summary['weight'] as double?) ?? 0.0;
    final reps = (summary['reps'] as int?) ?? 0;

    return WorkoutExercise(
      id: exerciseId,
      name: meta.name,
      tag: _mapExerciseTag(meta),
      muscles: meta.primaryMuscle.isNotEmpty
          ? meta.primaryMuscle
          : 'Não especificado',
      variation: 'Traditional',
      series: series.length,
      reps: reps > 0 ? reps.toString() : '-',
      weight: weight > 0 ? '${weight}kg' : '0kg',
      rir: (summary['rir'] as int?) ?? 0,
      restTime: (summary['restTime'] as int?) ?? 0,
      entries: entries,
    );
  }

  /// Convert multiple groups to WorkoutExercises
  /// Expected input: grouped map from SerieLogGrouper
  static List<WorkoutExercise> mapFromGroups(
    Map<String, List<SerieLogDto>> grouped,
    Map<String, ExerciseMetadata> exerciseMeta,
  ) {
    return grouped.entries.map((entry) {
      final exerciseId = entry.key;
      final seriesList = entry.value;
      final meta =
          exerciseMeta[exerciseId] ??
          ExerciseMetadata(
            id: exerciseId,
            name: '',
            category: '',
            primaryMuscle: 'Não especificado',
            tags: [],
          );

      return map(exerciseId, seriesList, meta);
    }).toList();
  }

  static ExerciseTag _mapExerciseTag(ExerciseMetadata meta) {
    // Priority: tags first, then category
    if (meta.tags.isNotEmpty) {
      final firstTag = meta.tags.first.toString().toLowerCase();
      final result = _tagToEnum(firstTag);
      if (result != null) return result;
    }

    final category = meta.category.toLowerCase();
    return _categoryToEnum(category);
  }

  static ExerciseTag? _tagToEnum(String tag) {
    switch (tag) {
      case 'multi':
      case 'composto':
        return ExerciseTag.multi;
      case 'iso':
      case 'isolamento':
        return ExerciseTag.iso;
      case 'cardio':
      case 'cardiovascular':
        return ExerciseTag.cardio;
      case 'funcional':
      case 'functional':
        return ExerciseTag.functional;
      default:
        return null;
    }
  }

  static ExerciseTag _categoryToEnum(String category) {
    switch (category) {
      case 'multi':
      case 'composto':
        return ExerciseTag.multi;
      case 'iso':
      case 'isolamento':
        return ExerciseTag.iso;
      case 'cardio':
      case 'cardiovascular':
        return ExerciseTag.cardio;
      case 'funcional':
      case 'functional':
        return ExerciseTag.functional;
      default:
        return ExerciseTag.multi;
    }
  }
}
