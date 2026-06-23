import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/workout_day/data/services/workout_log_service.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_draft.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';
import 'package:iron_log/features/workout_day/domain/repositories/workout_draft_repository.dart';

class _RecordingDraftRepository implements WorkoutDraftRepository {
  Map<String, dynamic>? lastPayload;
  PendingOperation? lastOperation;
  String? lastDraftId;

  @override
  Future<void> deleteAfterSuccessfulUpload(String draftId) async {}

  @override
  Future<WorkoutDraft?> getActiveInProgress(String userId) async => null;

  @override
  Future<WorkoutDraft?> getById(String draftId) async => WorkoutDraft(
    id: draftId,
    userId: 'user-test',
    status: WorkoutDraftStatus.inProgress,
    pendingOperation: PendingOperation.create,
    snapshotJson: '{}',
    startedAt: DateTime(2026, 6, 1),
  );

  @override
  Future<List<WorkoutDraft>> listPendingUpload(String userId) async => [];

  @override
  Future<void> markPendingUpload({
    required String draftId,
    required Map<String, dynamic> apiPayload,
    String? serverWorkoutId,
    required PendingOperation operation,
    DateTime? endedAt,
    DraftUploadError? error,
  }) async {
    lastDraftId = draftId;
    lastPayload = apiPayload;
    lastOperation = operation;
  }

  @override
  Future<void> recordUploadFailure(String draftId, DraftUploadError error) async {}

  @override
  Future<void> saveInProgress(WorkoutDraft draft) async {}
}

void main() {
  final exercises = <WorkoutExercise>[
    const WorkoutExercise(
      id: 'ex-1',
      name: 'Supino',
      tag: ExerciseTag.multi,
      muscles: 'Peito',
      variation: 'Traditional',
      series: 3,
      reps: '10',
      weight: '60',
      rir: 2,
      restTime: 90,
      entries: [],
    ),
  ];

  test('buildCreatePayload includes exercises for pending upload snapshot', () {
    final service = WorkoutLogService();
    final startedAt = DateTime(2026, 6, 1, 10);
    final endedAt = DateTime(2026, 6, 1, 11);

    final payload = service.buildCreatePayload(
      exercises: exercises,
      routineId: 'routine-1',
      startedAt: startedAt,
      endedAt: endedAt,
      sessionId: 'sess-1',
    );

    expect(payload['sessionId'], 'sess-1');
    expect(payload['exercises'], isA<List>());
    expect((payload['exercises'] as List).length, 1);
    expect(payload['endedAt'], endedAt.toIso8601String());
  });

  test('buildPatchPayload preserves exercise list for deferred PATCH', () {
    final service = WorkoutLogService();
    final payload = service.buildPatchPayload(
      exercises: exercises,
      startedAt: DateTime(2026, 6, 1, 10),
      endedAt: DateTime(2026, 6, 1, 11),
    );

    expect((payload['exercises'] as List).first, isA<Map>());
  });

  test('WorkoutUploadDeferredException exposes draftId', () {
    final error = WorkoutUploadDeferredException(draftId: 'draft-xyz');
    expect(error.draftId, 'draft-xyz');
    expect(error.toString(), contains('pendente'));
  });

  test('markPendingUpload contract stores POST payload from service shape', () async {
    final repo = _RecordingDraftRepository();
    final service = WorkoutLogService(drafts: repo);
    final payload = service.buildCreatePayload(
      exercises: exercises,
      startedAt: DateTime(2026, 6, 1, 10),
      endedAt: DateTime(2026, 6, 1, 11),
    );

    await repo.markPendingUpload(
      draftId: 'draft-1',
      apiPayload: payload,
      operation: PendingOperation.create,
      endedAt: DateTime(2026, 6, 1, 11),
      error: const DraftUploadError(type: 'connectionError'),
    );

    expect(repo.lastDraftId, 'draft-1');
    expect(repo.lastOperation, PendingOperation.create);
    expect(repo.lastPayload?['exercises'], isNotEmpty);
  });
}
