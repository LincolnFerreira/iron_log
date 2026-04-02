import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';

/// Provider que busca o histórico de treinos do usuário logado.
final workoutHistoryProvider =
    FutureProvider<List<WorkoutHistory>>((ref) async {
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
    final endedAt =
        map['endedAt'] != null ? DateTime.parse(map['endedAt']) : null;
    final duration =
        endedAt != null ? endedAt.difference(startedAt) : Duration.zero;
    final seriesCount = (map['series'] as List<dynamic>?)?.length ?? 0;

    return WorkoutHistory(
      routineName: routineName,
      date: startedAt,
      duration: duration,
      seriesCount: seriesCount,
    );
  }).toList();
});
