import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/http_service.dart';
import '../../domain/entities/workout_summary.dart';
import '../../domain/entities/exercise_summary.dart';
import '../../domain/entities/serie_log.dart';

// Provider para obter o resumo de uma sessão concluída
final workoutSummaryProvider = FutureProvider.family<WorkoutSummary, String>((
  ref,
  sessionId,
) async {
  final httpService = ref.watch(httpServiceProvider);
  return _fetchWorkoutSummary(httpService, sessionId);
});

// Provider para armazenar e gerenciar o resumo em memória
final workoutSummaryStateProvider = StateProvider<WorkoutSummary?>(
  (ref) => null,
);

/// Busca o resumo da sessão do backend
Future<WorkoutSummary> _fetchWorkoutSummary(
  HttpService httpService,
  String sessionId,
) async {
  // TODO: Substituir com endpoint real do backend quando disponível
  // Por enquanto, retorna dados de exemplo para teste

  try {
    // Se houver um endpoint real, descomente:
    // final url = ApiEndpoints.workoutSummary(sessionId);
    // final response = await httpService.get(url);
    // if (response.statusCode == 200) {
    //   return WorkoutSummary.fromJson(response.data);
    // }

    // Mock data para demonstração
    return WorkoutSummary(
      sessionName: 'Peito & Tríceps',
      date: DateTime.now(),
      duration: const Duration(minutes: 45, seconds: 32),
      exercises: [
        ExerciseSummary(
          id: '1',
          name: 'Supino Reto',
          muscleGroup: 'Peito',
          series: [
            const SerieLog(
              serieNumber: 1,
              type: 'warmup',
              weight: '20kg',
              reps: '10',
              rir: '--',
              status: 'completed',
            ),
            const SerieLog(
              serieNumber: 2,
              type: 'work',
              weight: '80kg',
              reps: '8',
              rir: '2',
              status: 'completed',
            ),
            const SerieLog(
              serieNumber: 3,
              type: 'work',
              weight: '80kg',
              reps: '7',
              rir: '3',
              status: 'completed',
            ),
          ],
        ),
        ExerciseSummary(
          id: '2',
          name: 'Rosca Direta',
          muscleGroup: 'Tríceps',
          series: [
            const SerieLog(
              serieNumber: 1,
              type: 'work',
              weight: '25kg',
              reps: '10',
              rir: '2',
              status: 'completed',
            ),
            const SerieLog(
              serieNumber: 2,
              type: 'work',
              weight: '25kg',
              reps: '9',
              rir: '2',
              status: 'completed',
            ),
            const SerieLog(
              serieNumber: 3,
              type: 'drop',
              weight: '20kg',
              reps: '8',
              rir: '1',
              status: 'marked_for_later',
            ),
          ],
        ),
      ],
      totalSeries: 6,
      completedSeries: 5,
      totalVolume: 685.0, // (20*10 + 80*8 + 80*7 + 25*10 + 25*9 + 20*8)
      isFirstWorkout: false,
      previousWorkouts: [
        WorkoutHistory(
          routineName: 'Peito & Tríceps',
          date: DateTime.now().subtract(const Duration(days: 2)),
          duration: const Duration(minutes: 42),
          seriesCount: 6,
        ),
        WorkoutHistory(
          routineName: 'Costas & Biciculo',
          date: DateTime.now().subtract(const Duration(days: 3)),
          duration: const Duration(hours: 1, minutes: 5),
          seriesCount: 8,
        ),
        WorkoutHistory(
          routineName: 'Perna',
          date: DateTime.now().subtract(const Duration(days: 4)),
          duration: const Duration(minutes: 58),
          seriesCount: 7,
        ),
      ],
    );
  } catch (e) {
    rethrow;
  }
}
