import '../../domain/entities/exercise_summary.dart';
import '../../domain/entities/serie_log.dart';
import '../../domain/entities/workout_summary.dart';
import '../../domain/entities/workout_exercise.dart';

class WorkoutMapper {
  static WorkoutSummary toSummary({
    required String sessionName,
    required DateTime date,
    required Duration duration,
    required List<WorkoutExercise> exercises,
  }) {
    final summaries = exercises.map((exercise) {
      final series = List<SerieLog>.generate(exercise.series, (index) {
        final serieNumber = index + 1;
        String serieType = 'work';
        if (serieNumber == 1) serieType = 'warmup';
        return SerieLog(
          serieNumber: serieNumber,
          type: serieType,
          weight: exercise.weight,
          reps: exercise.reps,
          rir: exercise.rir.toString(),
          status: 'completed',
        );
      });

      return ExerciseSummary(
        id: exercise.id,
        name: exercise.name,
        muscleGroup: exercise.muscles,
        series: series,
      );
    }).toList();

    return WorkoutSummary(
      sessionName: sessionName,
      date: date,
      duration: duration,
      exercises: summaries,
      totalSeries: exercises.fold<int>(0, (s, e) => s + e.series),
      completedSeries: exercises.fold<int>(0, (s, e) => s + e.series),
      totalVolume: exercises.fold<double>(0.0, (sum, ex) {
        final weightStr = ex.weight.replaceAll(RegExp(r'[^0-9.]'), '');
        final weight = double.tryParse(weightStr) ?? 0.0;
        return sum + (weight * ex.series);
      }),
      isFirstWorkout: false,
      previousWorkouts: [],
    );
  }
}
