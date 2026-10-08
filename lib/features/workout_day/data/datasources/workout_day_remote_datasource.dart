import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_set_history.dart';
import 'package:iron_log/features/workout_day/domain/entities/suggestion_result.dart';

/// Remote API for workout-day session/workout/exercise helpers.
class WorkoutDayRemoteDataSource {
  WorkoutDayRemoteDataSource(this._http);

  final HttpService _http;

  Future<Map<String, dynamic>> fetchSession(String sessionId) async {
    final response = await _http.get(ApiEndpoints.sessionById(sessionId));
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar sessão: ${response.statusCode}');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<void> removeExerciseFromSession(
    String sessionId,
    String exerciseId,
  ) async {
    final response = await _http.delete(
      ApiEndpoints.removeExerciseFromSession(sessionId, exerciseId),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao remover exercício: ${response.statusCode}');
    }
  }

  Future<void> patchSessionExercises(
    String sessionId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _http.patch(
      '${ApiEndpoints.sessionById(sessionId)}/exercises',
      data: payload,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao salvar exercícios: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchWorkout(String workoutId) async {
    final response = await _http.get(ApiEndpoints.workoutById(workoutId));
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar treino: ${response.statusCode}');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<void> patchWorkout(
    String workoutId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _http.patch(
      ApiEndpoints.workoutById(workoutId),
      data: payload,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar treino: ${response.statusCode}');
    }
  }

  Future<ExerciseSetHistory> fetchExerciseLastSets(
    String exerciseId, {
    String? stationId,
  }) async {
    final response = await _http.get(
      ApiEndpoints.exerciseLastSets(exerciseId, stationId: stationId),
    );
    return ExerciseSetHistory.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<SuggestionResult> fetchExerciseSuggestion(
    String exerciseId, {
    String? stationId,
  }) async {
    final response = await _http.get(
      ApiEndpoints.exerciseSuggestion(exerciseId, stationId: stationId),
    );
    return SuggestionResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createWorkoutActivity(
    Map<String, dynamic> payload,
  ) async {
    final response = await _http.post(
      ApiEndpoints.createWorkout,
      data: payload,
    );
    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected response from server when creating activity',
      );
    }
    return data;
  }
}
