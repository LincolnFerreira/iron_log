import 'search_exercise.dart';

/// Resposta do endpoint GET /exercises/browse.
class ExerciseBrowseResult {
  final List<SearchExercise> exercises;
  final List<String> muscles;

  const ExerciseBrowseResult({
    required this.exercises,
    required this.muscles,
  });
}
