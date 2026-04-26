import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

import 'api_field_names.dart';
import 'exercise_config_dto.dart';

/// Represents exercise metadata from the Exercise object
class ExerciseDataDto {
  final String? id;
  final String? name;
  final String? category;
  final String? primaryMuscle;
  final List<dynamic> tags;

  ExerciseDataDto({
    this.id,
    this.name,
    this.category,
    this.primaryMuscle,
    this.tags = const [],
  });

  factory ExerciseDataDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ExerciseDataDto();

    // Parse primaryMuscle — can be object { name: "Chest" } or string (CUID/name)
    final primaryMuscleRaw = json[ApiFieldNames.primaryMuscle];
    String? muscleName;
    if (primaryMuscleRaw is Map<String, dynamic>) {
      muscleName = primaryMuscleRaw['name']?.toString();
    } else if (primaryMuscleRaw is String && primaryMuscleRaw.isNotEmpty) {
      muscleName = primaryMuscleRaw;
    }

    return ExerciseDataDto(
      id: json[ApiFieldNames.id]?.toString(),
      name: json[ApiFieldNames.name]?.toString(),
      category: json[ApiFieldNames.category]?.toString(),
      primaryMuscle: muscleName,
      tags: json[ApiFieldNames.tags] as List<dynamic>? ?? [],
    );
  }

  /// Maps exercise data to ExerciseTag inline
  ExerciseTag toTag() {
    // Priority: tags first, then category
    if (tags.isNotEmpty) {
      final firstTag = tags.first.toString().toLowerCase();
      switch (firstTag) {
        case 'multi' || 'composto':
          return ExerciseTag.multi;
        case 'iso' || 'isolamento':
          return ExerciseTag.iso;
        case 'cardio' || 'cardiovascular':
          return ExerciseTag.cardio;
        case 'funcional' || 'functional':
          return ExerciseTag.functional;
      }
    }

    final categoryLower = category?.toLowerCase() ?? '';
    switch (categoryLower) {
      case 'multi' || 'composto':
        return ExerciseTag.multi;
      case 'iso' || 'isolamento':
        return ExerciseTag.iso;
      case 'cardio' || 'cardiovascular':
        return ExerciseTag.cardio;
      case 'funcional' || 'functional':
        return ExerciseTag.functional;
      default:
        return ExerciseTag.multi;
    }
  }
}

/// Represents a SessionExercise from /session/:id response
class SessionExerciseDto {
  final String? exerciseId;
  final String? sessionId;
  final int? order;
  final bool? isActive;
  final ExerciseDataDto exercise;
  final ExerciseConfigDto config;

  SessionExerciseDto({
    this.exerciseId,
    this.sessionId,
    this.order,
    this.isActive,
    required this.exercise,
    required this.config,
  });

  factory SessionExerciseDto.fromJson(Map<String, dynamic> json) {
    final exerciseData = json[ApiFieldNames.exercise] as Map<String, dynamic>?;
    final configData = json[ApiFieldNames.config] as Map<String, dynamic>?;

    return SessionExerciseDto(
      exerciseId: json[ApiFieldNames.exerciseId]?.toString(),
      sessionId: json[ApiFieldNames.sessionId]?.toString(),
      order: (json[ApiFieldNames.order] as num?)?.toInt(),
      isActive: json[ApiFieldNames.isActive] as bool?,
      exercise: ExerciseDataDto.fromJson(exerciseData),
      config: ExerciseConfigDto.fromJson(configData),
    );
  }

  /// Convert DTO to domain entity
  WorkoutExercise toEntity() {
    final series = config.series;
    final entries = series.asMap().entries.map((e) {
      // Determine series type. If label is missing and this is the first
      // series of multiple entries, treat it as warm-up by default.
      final label = e.value.label;
      final isFirst = e.key == 0;
      final type = (label == null && isFirst && series.length > 1)
          ? 0
          : _labelToType(label);

      return SeriesEntry(
        index: e.key,
        type: type,
        weight: (e.value.weight ?? 0).toString(),
        reps: (e.value.reps ?? 0).toString(),
        done: false,
      );
    }).toList();

    final firstSeries = series.isNotEmpty ? series.first : null;
    final weight = firstSeries?.weight ?? 0.0;
    final reps = firstSeries?.reps ?? 0;

    return WorkoutExercise(
      id: exerciseId ?? '',
      name: exercise.name ?? '',
      tag: exercise.toTag(),
      muscles: exercise.primaryMuscle ?? 'Não especificado',
      variation: config.variation ?? 'Traditional',
      // TODO(SERIES_DYNAMIC): Default series fallback when source omits series.
      // Make this configurable in future instead of hardcoding here.
      series: series.isNotEmpty ? series.length : 1,
      reps: reps > 0 ? reps.toString() : '-',
      weight: weight > 0 ? weight.toString() : '0',
      rir: firstSeries?.rir ?? 0,
      restTime: firstSeries?.restTime ?? 0,
      order: order,
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
