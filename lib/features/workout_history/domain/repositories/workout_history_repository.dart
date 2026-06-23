import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';

abstract class WorkoutHistoryRepository {
  Future<List<WorkoutHistory>> getWorkoutHistory();

  Future<WorkoutHistory?> getLastWorkoutForRoutine(String routineId);
}
