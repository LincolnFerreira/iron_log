import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';

/// Busca o último treino registrado de uma rotina específica.
/// Retorna null se nenhum treino existir para essa rotina.
final routineLastWorkoutProvider =
    FutureProvider.family<WorkoutHistory?, String>((ref, routineId) async {
      final http = ref.watch(httpServiceProvider);

      try {
        final response = await http.get(
          '/routine/$routineId/workouts',
          queryParameters: {'take': 1},
        );
        final List<dynamic> data = response.data as List<dynamic>;
        if (data.isEmpty) return null;

        final map = data.first as Map<String, dynamic>;

        final routineName =
            (map['routine'] as Map<String, dynamic>?)?['name']?.toString() ??
            'Treino';

        final startedAt = map['startedAt'] != null
            ? DateTime.parse(map['startedAt'] as String)
            : DateTime.now();
        final endedAt = map['endedAt'] != null
            ? DateTime.parse(map['endedAt'] as String)
            : null;
        final duration = endedAt != null
            ? endedAt.difference(startedAt)
            : Duration.zero;

        final allSeriesRaw = (map['series'] as List<dynamic>?) ?? [];

        final Map<String, int> exerciseCount = {};
        double totalVolume = 0;

        for (final s in allSeriesRaw) {
          final sMap = s as Map<String, dynamic>;
          final name =
              (sMap['exercise'] as Map<String, dynamic>?)?['name']
                  ?.toString() ??
              'Exercício';
          exerciseCount[name] = (exerciseCount[name] ?? 0) + 1;
          final weight = (sMap['weightKg'] as num?)?.toDouble() ?? 0;
          final reps = (sMap['reps'] as num?)?.toInt() ?? 0;
          totalVolume += weight * reps;
        }

        final exercises = exerciseCount.entries
            .map(
              (e) => WorkoutHistoryExercise(
                exerciseName: e.key,
                seriesCount: e.value,
                completedSeries: e.value,
              ),
            )
            .toList();

        return WorkoutHistory(
          id: map['id']?.toString() ?? '',
          routineName: routineName,
          sessionName: null,
          date: startedAt,
          duration: duration,
          seriesCount: allSeriesRaw.length,
          completedSeries: allSeriesRaw.length,
          totalSeries: allSeriesRaw.length,
          totalVolume: totalVolume,
          hasPR: false,
          exercises: exercises,
        );
      } catch (_) {
        return null;
      }
    });
