import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/core/database/app_database.dart';
import 'package:iron_log/features/workout_day/data/datasources/workout_draft_local_datasource.dart';
import 'package:iron_log/features/workout_day/data/mappers/workout_draft_snapshot_mapper.dart';
import 'package:iron_log/features/workout_day/data/repositories/workout_draft_repository_impl.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_draft.dart';
import 'package:iron_log/features/workout_day/domain/enums/workout_screen_mode.dart';

void main() {
  late AppDatabase db;
  late WorkoutDraftRepositoryImpl repository;
  final mapper = WorkoutDraftSnapshotMapper();

  WorkoutDraft buildDraft({
    required String id,
    required String userId,
    WorkoutDraftStatus status = WorkoutDraftStatus.inProgress,
  }) {
    final snapshot = mapper.fromExecutionState(
      exercises: const [],
      screenMode: WorkoutScreenMode.execution,
      workoutStarted: true,
      subtitle: 'Treino A',
      sessionId: 'sess-1',
    );
    return WorkoutDraft(
      id: id,
      userId: userId,
      status: status,
      pendingOperation: PendingOperation.create,
      snapshotJson: mapper.encode(snapshot),
      startedAt: DateTime(2026, 6, 1, 10),
      sessionId: 'sess-1',
    );
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = WorkoutDraftRepositoryImpl(WorkoutDraftLocalDataSource(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('saveInProgress keeps only one inProgress draft per user', () async {
    const userId = 'user-1';
    await repository.saveInProgress(buildDraft(id: 'draft-a', userId: userId));
    await repository.saveInProgress(buildDraft(id: 'draft-b', userId: userId));

    final active = await repository.getActiveInProgress(userId);
    expect(active?.id, 'draft-b');

    final old = await repository.getById('draft-a');
    expect(old, isNull);
  });

  test('markPendingUpload transitions inProgress to pendingUpload', () async {
    const userId = 'user-1';
    const draftId = 'draft-1';
    await repository.saveInProgress(buildDraft(id: draftId, userId: userId));

    await repository.markPendingUpload(
      draftId: draftId,
      apiPayload: {'exercises': []},
      operation: PendingOperation.create,
      endedAt: DateTime(2026, 6, 1, 11),
    );

    final active = await repository.getActiveInProgress(userId);
    expect(active, isNull);

    final pending = await repository.listPendingUpload(userId);
    expect(pending.length, 1);
    expect(pending.first.id, draftId);
    expect(pending.first.status, WorkoutDraftStatus.pendingUpload);
    expect(pending.first.apiPayloadJson, isNotNull);
  });

  test('deleteAfterSuccessfulUpload removes draft row', () async {
    const userId = 'user-1';
    const draftId = 'draft-1';
    await repository.saveInProgress(buildDraft(id: draftId, userId: userId));
    await repository.markPendingUpload(
      draftId: draftId,
      apiPayload: {'exercises': []},
      operation: PendingOperation.create,
    );

    await repository.deleteAfterSuccessfulUpload(draftId);

    expect(await repository.getById(draftId), isNull);
    expect(await repository.listPendingUpload(userId), isEmpty);
  });
}
