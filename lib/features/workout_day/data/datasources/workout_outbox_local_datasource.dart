import 'package:iron_log/core/database/app_database.dart';
import '../../domain/entities/workout_draft.dart';
import '../../domain/repositories/workout_draft_repository.dart';

/// @deprecated Novos writes vão para [WorkoutDraftRepository].
class WorkoutOutboxLocalDataSource {
  WorkoutOutboxLocalDataSource(this._db, {WorkoutDraftRepository? drafts})
    : _drafts = drafts;

  final AppDatabase _db;
  final WorkoutDraftRepository? _drafts;

  Future<void> enqueuePost({
    required String rowId,
    required String userId,
    required Map<String, dynamic> workoutPayload,
  }) async {
    if (_drafts == null) return;
    await _drafts.markPendingUpload(
      draftId: rowId,
      apiPayload: workoutPayload,
      operation: PendingOperation.create,
      endedAt: DateTime.tryParse(
        workoutPayload['endedAt']?.toString() ?? '',
      ),
    );
  }

  Future<void> enqueuePatch({
    required String rowId,
    required String userId,
    required String workoutId,
    required Map<String, dynamic> patchPayload,
  }) async {
    if (_drafts == null) return;
    await _drafts.markPendingUpload(
      draftId: rowId,
      apiPayload: patchPayload,
      serverWorkoutId: workoutId,
      operation: PendingOperation.patch,
      endedAt: DateTime.tryParse(patchPayload['endedAt']?.toString() ?? ''),
    );
  }
}
