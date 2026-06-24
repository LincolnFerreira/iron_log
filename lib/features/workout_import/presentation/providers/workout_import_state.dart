import '../../domain/entities/parsed_workout_import.dart';

class WorkoutImportReviewState {
  final String draftId;
  final String rawText;
  final ParsedWorkoutImport snapshot;
  final bool showOriginalText;
  final bool isSubmitting;

  const WorkoutImportReviewState({
    required this.draftId,
    required this.rawText,
    required this.snapshot,
    this.showOriginalText = false,
    this.isSubmitting = false,
  });

  WorkoutImportReviewState copyWith({
    ParsedWorkoutImport? snapshot,
    bool? showOriginalText,
    bool? isSubmitting,
  }) {
    return WorkoutImportReviewState(
      draftId: draftId,
      rawText: rawText,
      snapshot: snapshot ?? this.snapshot,
      showOriginalText: showOriginalText ?? this.showOriginalText,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
