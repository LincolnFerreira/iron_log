import '../entities/workout_draft.dart';

abstract class WorkoutDraftRepository {
  Future<WorkoutDraft?> getActiveInProgress(String userId);

  Future<List<WorkoutDraft>> listPendingUpload(String userId);

  Future<WorkoutDraft?> getById(String draftId);

  Future<void> saveInProgress(WorkoutDraft draft);

  Future<void> markPendingUpload({
    required String draftId,
    required Map<String, dynamic> apiPayload,
    String? serverWorkoutId,
    required PendingOperation operation,
    DateTime? endedAt,
    DraftUploadError? error,
  });

  Future<void> deleteAfterSuccessfulUpload(String draftId);

  Future<void> recordUploadFailure(String draftId, DraftUploadError error);
}
