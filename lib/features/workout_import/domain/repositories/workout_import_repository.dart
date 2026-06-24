import '../entities/parsed_workout_import.dart';

abstract class WorkoutImportRepository {
  Future<WorkoutImportDraft> parseText(String rawText, String userId);

  Future<WorkoutImportDraft?> getDraft(String draftId);

  Future<List<WorkoutImportDraft>> listActiveDrafts(String userId);

  Future<void> saveReviewEdits(String draftId, ParsedWorkoutImport snapshot);

  Future<WorkoutImportConfirmResult> confirm(String draftId);

  Future<void> discard(String draftId);
}
