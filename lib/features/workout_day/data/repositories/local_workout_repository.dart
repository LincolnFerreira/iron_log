import 'package:drift/drift.dart';
import 'package:iron_log/core/database/app_database.dart';
import 'package:iron_log/features/workout_day/data/models/voice_parsed_result.dart';

/// Small repository responsible for writing parsed voice input into local DB
/// using Drift companions. Data is marked as `pendingSync = true` and
/// `version = 1` so the existing sync manager will pick it up.
class LocalWorkoutRepository {
  final AppDatabase db;

  LocalWorkoutRepository(this.db);

  /// Saves a workout session locally and returns the inserted WorkoutSession id.
  Future<String> saveWorkoutLocal({
    required String userId,
    String? sessionTemplateId,
    String? routineId,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<ResolvedParsedExercise> exercises,
  }) async {
    String generateId() => DateTime.now().millisecondsSinceEpoch.toString();

    final wsId = generateId();

    final companion = WorkoutSessionsCompanion.insert(
      id: wsId,
      userId: userId,
      routineId: routineId == null ? const Value.absent() : Value(routineId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      isManual: const Value(true),
      notes: const Value.absent(),
      deviceId: const Value.absent(),
      totalVolume: const Value.absent(),
      topSetsCount: const Value.absent(),
      avgRIR: const Value.absent(),
      createdAt: const Value.absent(),
      updatedAt: const Value.absent(),
      version: const Value(1),
      pendingSync: const Value(true),
    );

    await db.into(db.workoutSessions).insert(companion);

    for (final resolved in exercises) {
      for (int i = 0; i < resolved.parsed.weights.length; i++) {
        final weight = resolved.parsed.weights[i];
        final reps = resolved.parsed.reps.length > i
            ? resolved.parsed.reps[i]
            : null;

        final serieComp = SerieLogsCompanion.insert(
          id: generateId(),
          sessionId: wsId,
          sessionExerciseSessionId: sessionTemplateId == null
              ? const Value.absent()
              : Value(sessionTemplateId),
          sessionExerciseExerciseId: resolved.matchedExerciseId == null
              ? const Value.absent()
              : Value(resolved.matchedExerciseId!),
          exerciseId: resolved.matchedExerciseId == null
              ? const Value.absent()
              : Value(resolved.matchedExerciseId!),
          setIndex: i,
          label: resolved.parsed.labels.length > i
              ? Value(resolved.parsed.labels[i])
              : const Value.absent(),
          reps: reps == null ? const Value.absent() : Value(reps),
          weight: weight == 0.0 ? const Value.absent() : Value(weight),
          rir: const Value.absent(),
          rirNote: const Value.absent(),
          restTime: const Value.absent(),
          cadence: const Value.absent(),
          isFailure: const Value.absent(),
          createdAt: const Value.absent(),
          updatedAt: const Value.absent(),
          version: const Value(1),
          pendingSync: const Value(true),
        );

        await db.into(db.serieLogs).insert(serieComp);
      }
    }

    return wsId;
  }
}
