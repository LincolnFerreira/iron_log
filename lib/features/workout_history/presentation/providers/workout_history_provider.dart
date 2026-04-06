import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';

/// Provider que busca o histórico de treinos do usuário logado.
final workoutHistoryProvider = FutureProvider<List<WorkoutHistory>>((
  ref,
) async {
  final auth = AuthService();
  final response = await auth.get(ApiEndpoints.workouts);
  final list = (response.data as List<dynamic>? ?? []);
  return list.map((item) {
    final map = item as Map<String, dynamic>;

    final routineName =
        (map['routine'] as Map<String, dynamic>?)?['name']?.toString() ??
        'Treino';

    final startedAt = map['startedAt'] != null
        ? DateTime.parse(map['startedAt'])
        : DateTime.now();
    final endedAt = map['endedAt'] != null
        ? DateTime.parse(map['endedAt'])
        : null;
    final duration = endedAt != null
        ? endedAt.difference(startedAt)
        : Duration.zero;

    // The API returns a flat 'series' array, each with a nested 'exercise'.
    // There is no 'status' field — saved series are implicitly completed.
    final allSeriesRaw = (map['series'] as List<dynamic>?) ?? [];

    // Extract sessionName from the first serie that carries sessionExercise.session
    // (populated by the backend findByUser include added for the edit flow).
    String? sessionName;
    for (final s in allSeriesRaw) {
      final sMap = s as Map<String, dynamic>;
      final se = sMap['sessionExercise'] as Map<String, dynamic>?;
      final session = se?['session'] as Map<String, dynamic>?;
      if (session != null) {
        sessionName = session['name']?.toString();
        break;
      }
    }

    // Group series by exercise name to build WorkoutHistoryExercise list
    final Map<String, int> exerciseSeriesCount = {};
    double totalVolume = 0;
    for (final s in allSeriesRaw) {
      final sMap = s as Map<String, dynamic>;
      final exerciseMap = sMap['exercise'] as Map<String, dynamic>?;
      final name = exerciseMap?['name']?.toString() ?? 'Exercício';
      exerciseSeriesCount[name] = (exerciseSeriesCount[name] ?? 0) + 1;
      final weight = (sMap['weightKg'] as num?)?.toDouble() ?? 0;
      final reps = (sMap['reps'] as num?)?.toInt() ?? 0;
      totalVolume += weight * reps;
    }

    final exercises = exerciseSeriesCount.entries
        .map(
          (e) => WorkoutHistoryExercise(
            exerciseName: e.key,
            seriesCount: e.value,
            completedSeries: e.value, // all saved series are completed
          ),
        )
        .toList();

    final totalSeries = allSeriesRaw.length;
    final completedSeries = totalSeries; // same reason

    // TODO: map hasPR when the API supports personal record detection
    return WorkoutHistory(
      id: map['id']?.toString() ?? '',
      routineName: routineName,
      sessionName: sessionName,
      date: startedAt,
      duration: duration,
      seriesCount: totalSeries,
      completedSeries: completedSeries,
      totalSeries: totalSeries,
      totalVolume: totalVolume,
      hasPR: false,
      exercises: exercises,
    );
  }).toList();
});
