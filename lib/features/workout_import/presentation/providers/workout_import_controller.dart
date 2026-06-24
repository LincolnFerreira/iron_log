import 'package:iron_log/features/auth/auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/effort_type.dart';
import '../../domain/entities/parsed_workout_import.dart';
import 'workout_import_providers.dart';
import 'workout_import_state.dart';

part 'workout_import_controller.g.dart';

@riverpod
class WorkoutImportController extends _$WorkoutImportController {
  @override
  Future<WorkoutImportReviewState?> build(String draftId) async {
    final draft = await ref.read(workoutImportRepositoryProvider).getDraft(draftId);
    if (draft == null) return null;
    return WorkoutImportReviewState(
      draftId: draft.id,
      rawText: draft.rawText,
      snapshot: draft.snapshot,
    );
  }

  Future<String?> submitText(String text) async {
    final userId = ref.read(authStateProvider).user?.uid;
    if (userId == null) return null;
    final draft = await ref.read(workoutImportRepositoryProvider).parseText(text, userId);
    ref.invalidateSelf();
    return draft.id;
  }

  Future<void> _persist(WorkoutImportReviewState current) async {
    await ref.read(workoutImportRepositoryProvider).saveReviewEdits(
          current.draftId,
          current.snapshot,
        );
    state = AsyncData(current);
  }

  Future<void> updateSetWeight({
    required String sessionKey,
    required String exerciseKey,
    required String setKey,
    required double? weight,
  }) async {
    final current = state.value;
    if (current == null) return;
    final updated = _updateSet(
      current,
      sessionKey,
      exerciseKey,
      setKey,
      (set) => set.copyWith(weight: weight),
    );
    await _persist(updated);
  }

  Future<void> updateSetReps({
    required String sessionKey,
    required String exerciseKey,
    required String setKey,
    required int? reps,
  }) async {
    final current = state.value;
    if (current == null) return;
    final updated = _updateSet(
      current,
      sessionKey,
      exerciseKey,
      setKey,
      (set) => set.copyWith(reps: reps),
    );
    await _persist(updated);
  }

  Future<void> updateExerciseName({
    required String sessionKey,
    required String exerciseKey,
    required String name,
  }) async {
    final current = state.value;
    if (current == null) return;
    final sessions = current.snapshot.sessions.map((session) {
      if (session.clientKey != sessionKey) return session;
      return session.copyWith(
        exercises: session.exercises.map((exercise) {
          if (exercise.clientKey != exerciseKey) return exercise;
          return exercise.copyWith(name: name);
        }).toList(),
      );
    }).toList();
    await _persist(
      current.copyWith(snapshot: current.snapshot.copyWith(sessions: sessions)),
    );
  }

  Future<void> setExerciseId({
    required String sessionKey,
    required String exerciseKey,
    required String exerciseId,
  }) async {
    final current = state.value;
    if (current == null) return;
    final sessions = current.snapshot.sessions.map((session) {
      if (session.clientKey != sessionKey) return session;
      return session.copyWith(
        exercises: session.exercises.map((exercise) {
          if (exercise.clientKey != exerciseKey) return exercise;
          return exercise.copyWith(exerciseId: exerciseId);
        }).toList(),
      );
    }).toList();
    await _persist(
      current.copyWith(snapshot: current.snapshot.copyWith(sessions: sessions)),
    );
  }

  Future<void> removeExercise({
    required String sessionKey,
    required String exerciseKey,
  }) async {
    final current = state.value;
    if (current == null) return;
    final sessions = current.snapshot.sessions.map((session) {
      if (session.clientKey != sessionKey) return session;
      return session.copyWith(
        exercises: session.exercises.map((exercise) {
          if (exercise.clientKey != exerciseKey) return exercise;
          return exercise.copyWith(removed: true);
        }).toList(),
      );
    }).toList();
    await _persist(
      current.copyWith(snapshot: current.snapshot.copyWith(sessions: sessions)),
    );
  }

  Future<void> removeSession(String sessionKey) async {
    final current = state.value;
    if (current == null) return;
    final sessions = current.snapshot.sessions.map((session) {
      if (session.clientKey != sessionKey) return session;
      return session.copyWith(removed: true);
    }).toList();
    await _persist(
      current.copyWith(snapshot: current.snapshot.copyWith(sessions: sessions)),
    );
  }

  Future<void> setSessionDate(String sessionKey, String? isoDate) async {
    final current = state.value;
    if (current == null) return;
    final sessions = current.snapshot.sessions.map((session) {
      if (session.clientKey != sessionKey) return session;
      return session.copyWith(
        scheduledDate: isoDate,
        dateConfidence: isoDate == null
            ? ConfidenceLevel.undetermined
            : ConfidenceLevel.high,
      );
    }).toList();
    await _persist(
      current.copyWith(snapshot: current.snapshot.copyWith(sessions: sessions)),
    );
  }

  void toggleOriginalText() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(showOriginalText: !current.showOriginalText),
    );
  }

  Future<WorkoutImportConfirmResult?> confirm() async {
    final current = state.value;
    if (current == null) return null;
    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      final result = await ref
          .read(workoutImportRepositoryProvider)
          .confirm(current.draftId);
      return result;
    } finally {
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isSubmitting: false));
      }
    }
  }

  Future<void> discard() async {
    final current = state.value;
    if (current == null) return;
    await ref.read(workoutImportRepositoryProvider).discard(current.draftId);
    state = const AsyncData(null);
  }

  WorkoutImportReviewState _updateSet(
    WorkoutImportReviewState current,
    String sessionKey,
    String exerciseKey,
    String setKey,
    ParsedImportSet Function(ParsedImportSet) transform,
  ) {
    final sessions = current.snapshot.sessions.map((session) {
      if (session.clientKey != sessionKey) return session;
      return session.copyWith(
        exercises: session.exercises.map((exercise) {
          if (exercise.clientKey != exerciseKey) return exercise;
          return exercise.copyWith(
            sets: exercise.sets.map((set) {
              if (set.clientKey != setKey) return set;
              return transform(set);
            }).toList(),
          );
        }).toList(),
      );
    }).toList();
    return current.copyWith(
      snapshot: current.snapshot.copyWith(sessions: sessions),
    );
  }
}
