import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

import 'api_field_names.dart';
import 'session_exercise_dto.dart';

/// Represents a SerieLog from /workout/:id response
class SerieLogDto {
  final String? id;
  final String sessionExerciseId; // REQUIRED - single source of truth
  final SessionExerciseDto? sessionExercise;
  final String? sessionId;
  final int? setIndex;
  final int? exerciseOrder;
  final String? label;
  final int? reps;
  final double? weight;
  final String? weightUnit;
  final int? rir;
  final String? rirNote;
  final int? restTime;
  final String? cadence;
  final bool? isFailure;

  SerieLogDto({
    this.id,
    required this.sessionExerciseId,
    this.sessionExercise,
    this.sessionId,
    this.setIndex,
    this.exerciseOrder,
    this.label,
    this.reps,
    this.weight,
    this.weightUnit,
    this.rir,
    this.rirNote,
    this.restTime,
    this.cadence,
    this.isFailure,
  });

  factory SerieLogDto.fromJson(Map<String, dynamic> json) {
    final sessionExerciseData =
        json[ApiFieldNames.sessionExercise] as Map<String, dynamic>?;

    // Helper function para converter valores numéricos com debug
    int? parseToInt(dynamic value, String fieldName) {
      try {
        if (value == null) return null;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.parse(value);
        print(
          '⚠️ Warning: $fieldName = $value (type: ${value.runtimeType}) não pôde ser parseado como int',
        );
        return null;
      } catch (e) {
        print('❌ Erro ao parsear $fieldName = $value: $e');
        return null;
      }
    }

    double? parseToDouble(dynamic value, String fieldName) {
      try {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.parse(value);
        print(
          '⚠️ Warning: $fieldName = $value (type: ${value.runtimeType}) não pôde ser parseado como double',
        );
        return null;
      } catch (e) {
        print(
          '❌ Erro ao parsear $fieldName = $value (${value.runtimeType}): $e',
        );
        return null;
      }
    }

    final convert = SerieLogDto(
      id: json[ApiFieldNames.id]?.toString(),
      sessionExerciseId:
          json[ApiFieldNames.sessionExerciseId]?.toString() ?? '',
      sessionExercise: sessionExerciseData != null
          ? SessionExerciseDto.fromJson(sessionExerciseData)
          : null,
      sessionId: json[ApiFieldNames.sessionId]?.toString(),
      setIndex: parseToInt(json[ApiFieldNames.setIndex], 'setIndex'),
      exerciseOrder: parseToInt(
        json[ApiFieldNames.exerciseOrder],
        'exerciseOrder',
      ),
      label: json[ApiFieldNames.label]?.toString(),
      reps: parseToInt(json[ApiFieldNames.reps], 'reps'),
      weight: parseToDouble(json[ApiFieldNames.weight], 'weight'),
      weightUnit: json[ApiFieldNames.weightUnit]?.toString() ?? 'kg',
      rir: parseToInt(json[ApiFieldNames.rir], 'rir'),
      rirNote: json[ApiFieldNames.rirNote]?.toString(),
      restTime: parseToInt(json[ApiFieldNames.restTime], 'restTime'),
      cadence: json[ApiFieldNames.cadence]?.toString(),
      isFailure: json[ApiFieldNames.isFailure] as bool?,
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

  /// Convert a group of SerieLogDtos (all from same SessionExercise) to WorkoutExercise
  static WorkoutExercise groupToEntity(
    String sessionExerciseId,
    List<SerieLogDto> series,
  ) {
    final entries = series
        .map((s) => s.toSeriesEntry(s.setIndex ?? 1))
        .toList();

    final first = series.first;
    final weight = first.weight ?? 0.0;
    final reps = first.reps ?? 0;
    final rir = first.rir ?? 0;
    final restTime = first.restTime ?? 0;

    // Access exercise data via sessionExercise nested object
    final exerciseData = first.sessionExercise?.exercise;

    return WorkoutExercise(
      id: sessionExerciseId,
      name: exerciseData?.name ?? '',
      tag: exerciseData?.toTag() ?? ExerciseTag.multi,
      muscles: exerciseData?.primaryMuscle ?? 'Não especificado',
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
