import 'package:iron_log/features/workout_day/domain/entities/exercise_set_history.dart';
import 'package:iron_log/features/workout_day/domain/entities/suggestion_result.dart';

/// Fronteira remota usada pelos providers de execução/edição de treino.
abstract class WorkoutDayRepository {
  Future<Map<String, dynamic>> fetchSession(String sessionId);

  Future<void> removeExerciseFromSession(String sessionId, String exerciseId);

  Future<void> patchSessionExercises(
    String sessionId,
    Map<String, dynamic> payload,
  );

  Future<Map<String, dynamic>> fetchWorkout(String workoutId);

  Future<void> patchWorkout(String workoutId, Map<String, dynamic> payload);

  Future<ExerciseSetHistory> fetchExerciseLastSets(
    String exerciseId, {
    String? stationId,
  });

  Future<SuggestionResult> fetchExerciseSuggestion(
    String exerciseId, {
    String? stationId,
  });

  Future<Map<String, dynamic>> createWorkoutActivity(
    Map<String, dynamic> payload,
  );
}
