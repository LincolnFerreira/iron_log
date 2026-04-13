import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

import 'api_field_names.dart';
import 'session_exercise_dto.dart';

/// Represents a SerieLog from /workout/:id response
class SerieLogDto {
  final String? id;
  final String? exerciseId;
  final String? sessionId;
  final int? setIndex;
  final String? label;
  final int? reps;
  final double? weight;
  final String? weightUnit;
  final int? rir;
  final String? rirNote;
  final int? restTime;
  final String? cadence;
  final bool? isFailure;
  final ExerciseDataDto? exercise;

  SerieLogDto({
    this.id,
    this.exerciseId,
    this.sessionId,
    this.setIndex,
    this.label,
    this.reps,
    this.weight,
    this.weightUnit,
    this.rir,
    this.rirNote,
    this.restTime,
    this.cadence,
    this.isFailure,
    this.exercise,
  });

  factory SerieLogDto.fromJson(Map<String, dynamic> json) {
    final exerciseData = json[ApiFieldNames.exercise] as Map<String, dynamic>?;

    final convert = SerieLogDto(
      id: json[ApiFieldNames.id]?.toString(),
      exerciseId: json[ApiFieldNames.exerciseId]?.toString(),
      sessionId: json[ApiFieldNames.sessionId]?.toString(),
      setIndex: (json[ApiFieldNames.setIndex] as num?)?.toInt(),
      label: json[ApiFieldNames.label]?.toString(),
      reps: (json[ApiFieldNames.reps] as num?)?.toInt(),
      weight: (json[ApiFieldNames.weight] as num?)?.toDouble(),
      weightUnit: json[ApiFieldNames.weightUnit]?.toString() ?? 'kg',
      rir: (json[ApiFieldNames.rir] as num?)?.toInt(),
      rirNote: json[ApiFieldNames.rirNote]?.toString(),
      restTime: (json[ApiFieldNames.restTime] as num?)?.toInt(),
      cadence: json[ApiFieldNames.cadence]?.toString(),
      isFailure: json[ApiFieldNames.isFailure] as bool?,
      exercise: exerciseData != null
          ? ExerciseDataDto.fromJson(exerciseData)
          : null,
    );
    return convert;
  }

  /// Convert single SerieLog to SeriesEntry (for building entries list)
  SeriesEntry toSeriesEntry(int index) {
    return SeriesEntry(
      index: index,
      type: _labelToType(label),
      weight: (weight ?? 0) > 0 ? weight.toString() : '0',
      reps: (reps ?? 0) > 0 ? reps.toString() : '0',
      done: true, // Already executed
    );
  }

  /// Convert a group of SerieLogDtos to WorkoutExercise
  static WorkoutExercise groupToEntity(
    String exerciseId,
    List<SerieLogDto> series,
  ) {
    final entries = series
        .asMap()
        .entries
        .map((e) => e.value.toSeriesEntry(e.key))
        .toList();

    final first = series.first;
    final weight = first.weight ?? 0.0;
    final reps = first.reps ?? 0;
    final rir = first.rir ?? 0;
    final restTime = first.restTime ?? 0;

    return WorkoutExercise(
      id: exerciseId,
      name: first.exercise?.name ?? '',
      tag: first.exercise?.toTag() ?? ExerciseTag.multi,
      muscles: first.exercise?.primaryMuscle ?? 'Não especificado',
      variation: 'Traditional',
      series: series.length,
      reps: reps > 0 ? reps.toString() : '-',
      weight: weight > 0 ? weight.toString() : '0',
      rir: rir,
      restTime: restTime,
      entries: entries,
    );
  }

  static int _labelToType(String? label) {
    if (label == null) return 2;
    switch (label.toLowerCase()) {
      case 'warm-up' || 'warmup' || 'aquecimento':
        return 0;
      case 'feeder' || 'prep' || 'preparação':
        return 1;
      case 'back-off' || 'backoff' || 'back off':
        return 3;
      default:
        return 2;
    }
  }
}
