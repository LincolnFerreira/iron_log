import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/weight_unit.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

/// DTO for deserializing a workout session for edit/load operations
class WorkoutEditDto {
  final String id;
  final String? routineId;
  final String? routineName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isManual;
  final List<WorkoutEditSerieLogDto> series;

  WorkoutEditDto({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startedAt,
    required this.endedAt,
    required this.isManual,
    required this.series,
  });

  /// Factory constructor to deserialize from API response.
  factory WorkoutEditDto.fromJson(Map<String, dynamic> json) {
    return WorkoutEditDto(
      id: json['id']?.toString() ?? '',
      routineId: json['routineId']?.toString(),
      routineName: (json['routine'] as Map<String, dynamic>?)?['name']
          ?.toString(),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      isManual: (json['isManual'] as bool?) ?? false,
      series: ((json['series'] as List<dynamic>?) ?? [])
          .map(
            (s) => WorkoutEditSerieLogDto.fromJson(s as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convert the flat series list into grouped WorkoutExercise list.
  ///
  /// Groups by [exerciseId] while preserving order of first appearance.
  /// Each group becomes one WorkoutExercise with its series as entries.
  List<WorkoutExercise> toWorkoutExercises() {
    final grouped = <String, List<WorkoutEditSerieLogDto>>{};
    final insertionOrder = <String>[];

    for (final s in series) {
      final exId = s.exerciseId;
      if (exId.isEmpty) continue;
      if (!grouped.containsKey(exId)) {
        grouped[exId] = [];
        insertionOrder.add(exId);
      }
      grouped[exId]!.add(s);
    }

    return insertionOrder.map((exId) {
      final group = grouped[exId]!;
      final first = group.first;

      final entries = group
          .asMap()
          .entries
          .map(
            (e) => SeriesEntry(
              index: e.key,
              type: _labelToType(e.value.label),
              weight: e.value.weight > 0 ? e.value.weight.toString() : '0',
              reps: e.value.reps > 0 ? e.value.reps.toString() : '0',
              done: true,
            ),
          )
          .toList();

      final weight = first.weight;
      final reps = first.reps;

      return WorkoutExercise(
        id: exId,
        name: first.exerciseName,
        tag: first.exerciseTag,
        muscles: first.exerciseMuscle,
        variation: 'Traditional',
        series: group.length,
        reps: reps > 0 ? reps.toString() : '-',
        weight: weight > 0 ? weight.toString() : '0',
        rir: first.rir ?? 0,
        restTime: first.restTime ?? 0,
        weightUnit: WeightUnit.fromString(first.weightUnit ?? 'kg'),
        entries: entries,
        notes: first.exerciseNotes,
      );
    }).toList();
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

/// DTO for a single series log in workout edit
class WorkoutEditSerieLogDto {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final ExerciseTag exerciseTag;
  final String exerciseMuscle;
  final String? label;
  final String? tag;
  final double weight;
  final int reps;
  final String? weightUnit;
  final int? rir;
  final int? restTime;
  final String? notes;
  final String? exerciseNotes;

  WorkoutEditSerieLogDto({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseTag,
    required this.exerciseMuscle,
    required this.label,
    required this.tag,
    required this.weight,
    required this.reps,
    required this.weightUnit,
    required this.rir,
    required this.restTime,
    required this.notes,
    required this.exerciseNotes,
  });

  factory WorkoutEditSerieLogDto.fromJson(Map<String, dynamic> json) {
    final exerciseData = json['exercise'] as Map<String, dynamic>? ?? {};
    final tags = exerciseData['tags'] as List<dynamic>? ?? [];

    // Parse primaryMuscle — can be object { name: "Chest" } or string
    final primaryMuscleRaw = exerciseData['primaryMuscle'];
    String muscleName = 'Não especificado';
    if (primaryMuscleRaw is Map<String, dynamic>) {
      muscleName = primaryMuscleRaw['name']?.toString() ?? 'Não especificado';
    } else if (primaryMuscleRaw is String && primaryMuscleRaw.isNotEmpty) {
      muscleName = primaryMuscleRaw;
    }

    // Parse tag from exercise tags array
    ExerciseTag exerciseTag = ExerciseTag.multi;
    if (tags.isNotEmpty) {
      final firstTag = tags.first.toString().toLowerCase();
      exerciseTag = _parseTag(firstTag);
    }

    return WorkoutEditSerieLogDto(
      id: json['id']?.toString() ?? '',
      exerciseId: json['exerciseId']?.toString() ?? '',
      exerciseName: exerciseData['name']?.toString() ?? '',
      exerciseTag: exerciseTag,
      exerciseMuscle: muscleName,
      label: json['label']?.toString(),
      tag: json['tag']?.toString(),
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      weightUnit: json['weightUnit']?.toString(),
      rir: (json['rir'] as num?)?.toInt(),
      restTime: (json['restTime'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
      exerciseNotes: json['exerciseNotes']?.toString(),
    );
  }

  static ExerciseTag _parseTag(String tag) {
    switch (tag) {
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
