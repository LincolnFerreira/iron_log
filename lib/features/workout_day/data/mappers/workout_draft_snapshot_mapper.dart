import 'dart:convert';

import '../../domain/entities/exercise_tag.dart';
import '../../domain/entities/series_entry.dart';
import '../../domain/entities/technique_block.dart';
import '../../domain/entities/technique_type.dart';
import '../../domain/entities/weight_unit.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/workout_draft.dart';
import '../../domain/enums/workout_screen_mode.dart';

class DraftSnapshotV1 {
  const DraftSnapshotV1({
    required this.screenMode,
    required this.workoutStarted,
    required this.exercises,
    this.subtitle,
    this.workoutSessionId,
    this.routineId,
    this.sessionId,
    this.manualDateIso,
  });

  final String screenMode;
  final bool workoutStarted;
  final List<WorkoutExercise> exercises;
  final String? subtitle;
  final String? workoutSessionId;
  final String? routineId;
  final String? sessionId;
  final String? manualDateIso;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'screenMode': screenMode,
    'workoutStarted': workoutStarted,
    'exercises': exercises
        .map(WorkoutDraftSnapshotMapper.exerciseToJson)
        .toList(),
    if (subtitle != null) 'subtitle': subtitle,
    if (workoutSessionId != null) 'workoutSessionId': workoutSessionId,
    if (routineId != null) 'routineId': routineId,
    if (sessionId != null) 'sessionId': sessionId,
    if (manualDateIso != null) 'manualDateIso': manualDateIso,
  };

  factory DraftSnapshotV1.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List<dynamic>? ?? [];
    return DraftSnapshotV1(
      screenMode: json['screenMode'] as String? ?? 'execution',
      workoutStarted: json['workoutStarted'] as bool? ?? false,
      exercises: rawExercises
          .map((e) => WorkoutDraftSnapshotMapper.exerciseFromJson(
                e as Map<String, dynamic>,
              ))
          .toList(),
      subtitle: json['subtitle'] as String?,
      workoutSessionId: json['workoutSessionId'] as String?,
      routineId: json['routineId'] as String?,
      sessionId: json['sessionId'] as String?,
      manualDateIso: json['manualDateIso'] as String?,
    );
  }
}

class WorkoutDraftSnapshotMapper {
  String encode(DraftSnapshotV1 snapshot) =>
      jsonEncode(snapshot.toJson());

  DraftSnapshotV1 decode(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return DraftSnapshotV1.fromJson(map);
  }

  DraftSnapshotV1 fromExecutionState({
    required List<WorkoutExercise> exercises,
    required WorkoutScreenMode screenMode,
    required bool workoutStarted,
    String? subtitle,
    String? workoutSessionId,
    String? routineId,
    String? sessionId,
    DateTime? manualDate,
  }) {
    return DraftSnapshotV1(
      screenMode: screenMode.name,
      workoutStarted: workoutStarted,
      exercises: exercises,
      subtitle: subtitle,
      workoutSessionId: workoutSessionId,
      routineId: routineId,
      sessionId: sessionId,
      manualDateIso: manualDate?.toIso8601String(),
    );
  }

  WorkoutDraftSummary toSummary(DraftSnapshotV1 snapshot, String draftId) {
    final name = snapshot.subtitle ?? 'Treino em andamento';
    return WorkoutDraftSummary(
      id: draftId,
      sessionName: name,
      exerciseCount: snapshot.exercises.length,
      startedAt: DateTime.now(),
      routineId: snapshot.routineId,
      sessionId: snapshot.sessionId,
    );
  }

  static Map<String, dynamic> exerciseToJson(WorkoutExercise e) => {
    'id': e.id,
    'name': e.name,
    'tag': e.tag.label,
    'muscles': e.muscles,
    'variation': e.variation,
    'series': e.series,
    'reps': e.reps,
    'weight': e.weight,
    'rir': e.rir,
    'restTime': e.restTime,
    'weightUnit': e.weightUnit.label,
    if (e.order != null) 'order': e.order,
    if (e.notes != null) 'notes': e.notes,
    'entries': e.entries.map(_entryToJson).toList(),
    'blocks': e.blocks.map(_blockToJson).toList(),
  };

  static WorkoutExercise exerciseFromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'] as List<dynamic>? ?? [];
    final blocksRaw = json['blocks'] as List<dynamic>? ?? [];
    return WorkoutExercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tag: ExerciseTag.fromString(json['tag']?.toString() ?? 'multi'),
      muscles: json['muscles']?.toString() ?? '',
      variation: json['variation']?.toString() ?? 'Traditional',
      series: (json['series'] as num?)?.toInt() ?? 3,
      reps: json['reps']?.toString() ?? '-',
      weight: json['weight']?.toString() ?? '0',
      rir: (json['rir'] as num?)?.toInt() ?? 2,
      restTime: (json['restTime'] as num?)?.toInt() ?? 120,
      weightUnit: WeightUnit.fromString(
        json['weightUnit']?.toString() ?? 'kg',
      ),
      order: (json['order'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
      entries: entriesRaw
          .map((e) => _entryFromJson(e as Map<String, dynamic>))
          .toList(),
      blocks: blocksRaw
          .map((b) => _blockFromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  static Map<String, dynamic> _entryToJson(SeriesEntry e) => {
    'index': e.index,
    'type': e.type,
    'weight': e.weight,
    'reps': e.reps,
    'done': e.done,
    'isDerived': e.isDerived,
    if (e.miniSetIndex != null) 'miniSetIndex': e.miniSetIndex,
    if (e.setType != null) 'setType': e.setType,
    if (e.techniqueBlockId != null) 'techniqueBlockId': e.techniqueBlockId,
  };

  static SeriesEntry _entryFromJson(Map<String, dynamic> json) => SeriesEntry(
    index: (json['index'] as num?)?.toInt() ?? 0,
    type: (json['type'] as num?)?.toInt() ?? 2,
    weight: json['weight']?.toString() ?? '0',
    reps: json['reps']?.toString() ?? '0',
    done: json['done'] as bool? ?? false,
    isDerived: json['isDerived'] as bool? ?? false,
    miniSetIndex: (json['miniSetIndex'] as num?)?.toInt(),
    setType: json['setType'] as String?,
    techniqueBlockId: json['techniqueBlockId'] as String?,
  );

  static Map<String, dynamic> _blockToJson(TechniqueBlock b) => {
    if (b.id != null) 'id': b.id,
    'type': b.type.name,
    'order': b.order,
    if (b.label != null) 'label': b.label,
    if (b.restBetweenMiniSets != null)
      'restBetweenMiniSets': b.restBetweenMiniSets,
    'entries': b.entries.map(_entryToJson).toList(),
    'terminatedEarly': b.terminatedEarly,
  };

  static TechniqueBlock _blockFromJson(Map<String, dynamic> json) {
    return TechniqueBlock(
      id: json['id'] as String?,
      type: TechniqueType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TechniqueType.normal,
      ),
      order: (json['order'] as num?)?.toInt() ?? 0,
      label: json['label'] as String?,
      restBetweenMiniSets: (json['restBetweenMiniSets'] as num?)?.toInt(),
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((e) => _entryFromJson(e as Map<String, dynamic>))
          .toList(),
      terminatedEarly: json['terminatedEarly'] as bool? ?? false,
    );
  }
}
