import 'package:iron_log/features/workout_day/data/datasources/workout_day_remote_datasource.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_set_history.dart';
import 'package:iron_log/features/workout_day/domain/entities/suggestion_result.dart';
import 'package:iron_log/features/workout_day/domain/repositories/workout_day_repository.dart';

class WorkoutDayRepositoryImpl implements WorkoutDayRepository {
  WorkoutDayRepositoryImpl(this._remote);

  final WorkoutDayRemoteDataSource _remote;

  @override
  Future<Map<String, dynamic>> fetchSession(String sessionId) =>
      _remote.fetchSession(sessionId);

  @override
  Future<void> removeExerciseFromSession(
    String sessionId,
    String exerciseId,
  ) =>
      _remote.removeExerciseFromSession(sessionId, exerciseId);

  @override
  Future<void> patchSessionExercises(
    String sessionId,
    Map<String, dynamic> payload,
  ) =>
      _remote.patchSessionExercises(sessionId, payload);

  @override
  Future<Map<String, dynamic>> fetchWorkout(String workoutId) =>
      _remote.fetchWorkout(workoutId);

  @override
  Future<void> patchWorkout(String workoutId, Map<String, dynamic> payload) =>
      _remote.patchWorkout(workoutId, payload);

  @override
  Future<ExerciseSetHistory> fetchExerciseLastSets(String exerciseId) =>
      _remote.fetchExerciseLastSets(exerciseId);

  @override
  Future<SuggestionResult> fetchExerciseSuggestion(String exerciseId) =>
      _remote.fetchExerciseSuggestion(exerciseId);

  @override
  Future<Map<String, dynamic>> createWorkoutActivity(
    Map<String, dynamic> payload,
  ) =>
      _remote.createWorkoutActivity(payload);
}
