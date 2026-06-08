import '../../domain/entities/exercise_summary.dart';
import '../../domain/entities/serie_log.dart';
import '../../domain/entities/series_entry.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/workout_summary.dart';
import '../../domain/mappers/technique_block_mapper.dart';

class WorkoutMapper {
  static WorkoutSummary toSummary({
    required String sessionName,
    required DateTime date,
    required Duration duration,
    required List<WorkoutExercise> exercises,
  }) {
    final summaries = exercises.map(_exerciseToSummary).toList();

    var totalSeries = 0;
    var completedSeries = 0;
    var totalVolume = 0.0;

    for (final summary in summaries) {
      totalSeries += summary.totalSeries;
      completedSeries += summary.completedSeries;
      for (final serie in summary.series) {
        totalVolume += _volumeForSerie(serie);
      }
    }

    return WorkoutSummary(
      sessionName: sessionName,
      date: date,
      duration: duration,
      exercises: summaries,
      totalSeries: totalSeries,
      completedSeries: completedSeries,
      totalVolume: totalVolume,
      isFirstWorkout: false,
      previousWorkouts: [],
    );
  }

  static ExerciseSummary _exerciseToSummary(WorkoutExercise exercise) {
    final series = _seriesFromExercise(exercise);
    return ExerciseSummary(
      id: exercise.id,
      name: exercise.name,
      muscleGroup: exercise.muscles,
      series: series,
    );
  }

  static List<SerieLog> _seriesFromExercise(WorkoutExercise exercise) {
    final entries = exercise.entries.isNotEmpty
        ? exercise.entries
        : TechniqueBlockMapper.flattenBlocks(
            TechniqueBlockMapper.ensureBlocks(exercise),
          );

    if (entries.isNotEmpty) {
      return entries
          .map(
            (entry) => SerieLog(
              serieNumber: entry.index + 1,
              type: _serieTypeFromEntry(entry),
              weight: _formatWeightDisplay(entry.weight, exercise.weightUnit.label),
              reps: entry.reps.isNotEmpty ? entry.reps : '--',
              rir: exercise.rir > 0 ? exercise.rir.toString() : '--',
              status: entry.done ? 'completed' : 'not_registered',
            ),
          )
          .toList();
    }

    if (exercise.series <= 0) {
      return const [];
    }

    return List<SerieLog>.generate(exercise.series, (index) {
      final serieNumber = index + 1;
      return SerieLog(
        serieNumber: serieNumber,
        type: serieNumber == 1 ? 'warmup' : 'work',
        weight: _formatWeightDisplay(exercise.weight, exercise.weightUnit.label),
        reps: exercise.reps.isNotEmpty ? exercise.reps : '--',
        rir: exercise.rir > 0 ? exercise.rir.toString() : '--',
        status: 'completed',
      );
    });
  }

  static String _serieTypeFromEntry(SeriesEntry entry) {
    switch (entry.type) {
      case 0:
        return 'warmup';
      case 1:
        return 'prep';
      case 3:
        return 'failure';
      case 2:
      default:
        return 'work';
    }
  }

  static String _formatWeightDisplay(String weight, String unit) {
    final trimmed = weight.trim();
    if (trimmed.isEmpty) return '--';
    if (trimmed.contains(RegExp(r'[a-zA-Z]'))) return trimmed;
    return '$trimmed$unit';
  }

  static double _volumeForSerie(SerieLog serie) {
    final weight = double.tryParse(
          serie.weight.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
    final reps =
        int.tryParse(RegExp(r'\d+').firstMatch(serie.reps)?.group(0) ?? '') ??
        0;
    return weight * reps;
  }
}
