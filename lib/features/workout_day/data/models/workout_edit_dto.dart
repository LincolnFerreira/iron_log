import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_block.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_type.dart';
import 'package:iron_log/features/workout_day/domain/entities/weight_unit.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';
import 'package:iron_log/features/workout_day/domain/mappers/technique_block_mapper.dart';

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
  /// Groups by [sessionExerciseId] (one card = one SessionExercise).
  /// Reconstructs technique blocks when present in API response.
  List<WorkoutExercise> toWorkoutExercises() {
    final grouped = <String, List<WorkoutEditSerieLogDto>>{};
    final insertionOrder = <String>[];

    for (final s in series) {
      final seId = s.sessionExerciseId;
      if (seId.isEmpty) continue;
      grouped.putIfAbsent(seId, () {
        insertionOrder.add(seId);
        return [];
      });
      grouped[seId]!.add(s);
    }

    return insertionOrder.map((seId) {
      final group = grouped[seId]!;
      final first = group.first;

      final blocks = _buildBlocksFromGroup(group);
      final entries = TechniqueBlockMapper.flattenBlocks(blocks);

      final weight = first.weight;
      final reps = first.reps;

      return WorkoutExercise(
        id: seId,
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
        blocks: blocks,
        notes: first.exerciseNotes,
      );
    }).toList();
  }

  List<TechniqueBlock> _buildBlocksFromGroup(List<WorkoutEditSerieLogDto> group) {
    final hasBlocks = group.any((s) => s.techniqueBlock != null);

    if (!hasBlocks) {
      final entries = group
          .map(
            (s) => SeriesEntry(
              index: s.setIndex,
              type: _labelToType(s.label),
              weight: s.weight > 0 ? s.weight.toString() : '0',
              reps: s.reps > 0 ? s.reps.toString() : '0',
              done: true,
            ),
          )
          .toList();
      return [
        TechniqueBlock(type: TechniqueType.normal, order: 0, entries: entries),
      ];
    }

    final blockMap = <String, List<WorkoutEditSerieLogDto>>{};
    final blockOrder = <String>[];

    for (final s in group) {
      final blockId = s.techniqueBlock?.id ?? '_implicit_normal';
      blockMap.putIfAbsent(blockId, () {
        blockOrder.add(blockId);
        return [];
      });
      blockMap[blockId]!.add(s);
    }

    return blockOrder.asMap().entries.map((entry) {
      final blockId = entry.value;
      final sets = blockMap[blockId]!;
      final meta = sets.first.techniqueBlock;
      final entries = sets
          .map(
            (s) => SeriesEntry(
              index: s.setIndex,
              type: _labelToType(s.label),
              weight: s.weight > 0 ? s.weight.toString() : '0',
              reps: s.reps > 0 ? s.reps.toString() : '0',
              done: true,
              isDerived: s.isDerived,
              miniSetIndex: s.miniSetIndex,
              setType: s.setType,
              techniqueBlockId: s.techniqueBlock?.id,
            ),
          )
          .toList();

      return TechniqueBlock(
        id: meta?.id,
        type: TechniqueType.fromApi(meta?.type),
        order: meta?.order ?? entry.key,
        label: meta?.label,
        restBetweenMiniSets: meta?.restBetweenMiniSets,
        entries: entries,
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
class WorkoutEditTechniqueBlockDto {
  final String id;
  final String type;
  final int order;
  final String? label;
  final int? restBetweenMiniSets;

  WorkoutEditTechniqueBlockDto({
    required this.id,
    required this.type,
    required this.order,
    this.label,
    this.restBetweenMiniSets,
  });

  factory WorkoutEditTechniqueBlockDto.fromJson(Map<String, dynamic> json) {
    return WorkoutEditTechniqueBlockDto(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'NORMAL',
      order: (json['order'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString(),
      restBetweenMiniSets: (json['restBetweenMiniSets'] as num?)?.toInt(),
    );
  }
}

/// DTO for a single series log in workout edit
class WorkoutEditSerieLogDto {
  final String id;
  final String sessionExerciseId;
  final String exerciseId;
  final String exerciseName;
  final ExerciseTag exerciseTag;
  final String exerciseMuscle;
  final int setIndex;
  final int exerciseOrder;
  final String? label;
  final String? tag;
  final double weight;
  final int reps;
  final String? weightUnit;
  final int? rir;
  final int? restTime;
  final String? notes;
  final String? exerciseNotes;
  final WorkoutEditTechniqueBlockDto? techniqueBlock;
  final bool isDerived;
  final int? miniSetIndex;
  final String? setType;

  WorkoutEditSerieLogDto({
    required this.id,
    required this.sessionExerciseId,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseTag,
    required this.exerciseMuscle,
    required this.setIndex,
    required this.exerciseOrder,
    required this.label,
    required this.tag,
    required this.weight,
    required this.reps,
    required this.weightUnit,
    required this.rir,
    required this.restTime,
    required this.notes,
    required this.exerciseNotes,
    this.techniqueBlock,
    this.isDerived = false,
    this.miniSetIndex,
    this.setType,
  });

  factory WorkoutEditSerieLogDto.fromJson(Map<String, dynamic> json) {
    final sessionExerciseData =
        json['sessionExercise'] as Map<String, dynamic>? ?? {};
    final exerciseData =
        sessionExerciseData['exercise'] as Map<String, dynamic>? ?? {};
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

    return WorkoutEditSerieLogDto(
      id: json['id']?.toString() ?? '',
      sessionExerciseId: json['sessionExerciseId']?.toString() ?? '',
      exerciseId: sessionExerciseData['exerciseId']?.toString() ?? '',
      exerciseName: exerciseData['name']?.toString() ?? '',
      exerciseTag: exerciseTag,
      exerciseMuscle: muscleName,
      setIndex: parseToInt(json['setIndex'], 'setIndex') ?? 1,
      exerciseOrder: parseToInt(json['exerciseOrder'], 'exerciseOrder') ?? 1,
      label: json['label']?.toString(),
      tag: json['tag']?.toString(),
      weight: parseToDouble(json['weight'], 'weight') ?? 0,
      reps: parseToInt(json['reps'], 'reps') ?? 0,
      weightUnit: json['weightUnit']?.toString(),
      rir: parseToInt(json['rir'], 'rir'),
      restTime: parseToInt(json['restTime'], 'restTime'),
      notes: json['notes']?.toString(),
      exerciseNotes: json['exerciseNotes']?.toString(),
      techniqueBlock: json['techniqueBlock'] != null
          ? WorkoutEditTechniqueBlockDto.fromJson(
              json['techniqueBlock'] as Map<String, dynamic>,
            )
          : null,
      isDerived: (json['isDerived'] as bool?) ?? false,
      miniSetIndex: parseToInt(json['miniSetIndex'], 'miniSetIndex'),
      setType: json['setType']?.toString(),
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
