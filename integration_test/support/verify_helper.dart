import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/auth_service.dart';

class WorkoutVerifyHelper {
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> fetchWorkout(String workoutId) async {
    final response = await _auth.get(ApiEndpoints.workoutById(workoutId));
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> fetchWorkoutList() async {
    final response = await _auth.get(ApiEndpoints.workouts);
    final data = response.data;
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  /// Retorna o treino de training mais recente (por startedAt).
  Future<Map<String, dynamic>?> fetchLatestTrainingWorkout() async {
    final list = await fetchWorkoutList();
    final training = list.where((w) => w['type'] != 'rest').toList();
    if (training.isEmpty) return null;

    training.sort((a, b) {
      final aDate = DateTime.tryParse(a['startedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['startedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return training.first;
  }

  Future<Map<String, dynamic>> fetchLatestTrainingWorkoutDetail() async {
    final latest = await fetchLatestTrainingWorkout();
    if (latest == null || latest['id'] == null) {
      throw StateError('Nenhum treino encontrado após finish');
    }
    return fetchWorkout(latest['id'] as String);
  }

  List<Map<String, dynamic>> extractSeries(Map<String, dynamic> workout) {
    final raw = workout['series'] as List<dynamic>? ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Set<String> techniqueBlockTypes(List<Map<String, dynamic>> series) {
    return series
        .map((s) => s['techniqueBlock'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map((b) => b['type']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toSet();
  }

  bool hasSeriesWith({
    required List<Map<String, dynamic>> series,
    required int reps,
    required num weight,
  }) {
    return series.any(
      (s) => s['reps'] == reps && (s['weight'] as num?) == weight,
    );
  }

  void expectTechniqueTypes(
    List<Map<String, dynamic>> series,
    Set<String> expected,
  ) {
    final types = techniqueBlockTypes(series);
    for (final type in expected) {
      if (!types.contains(type)) {
        throw StateError(
          'Esperava bloco $type no treino salvo; encontrados: $types',
        );
      }
    }
  }
}
