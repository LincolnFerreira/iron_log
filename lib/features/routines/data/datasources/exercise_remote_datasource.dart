import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/routines/data/models/exercise_browse_dto.dart';
import 'package:iron_log/features/routines/domain/entities/exercise_browse_result.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';

class ExerciseRemoteDataSource {
  ExerciseRemoteDataSource(this._http);

  final HttpService _http;

  Future<ExerciseBrowseResult> browseExercises() async {
    final response = await _http.get(ApiEndpoints.exerciseBrowse);
    final dto = ExerciseBrowseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
    return dto.toEntity();
  }

  Future<SearchExercise> createExercise({
    required String name,
    String? primaryMuscle,
    String? equipment,
  }) async {
    final response = await _http.post(
      ApiEndpoints.exerciseCreate,
      data: {
        'name': name,
        if (primaryMuscle != null) 'primaryMuscle': primaryMuscle,
        if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
      },
    );
    return SearchExercise.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<SearchExercise>> searchExercises(
    String query, {
    int limit = 30,
  }) async {
    final response = await _http.get(
      ApiEndpoints.exerciseSearchPath,
      queryParameters: {'q': query, 'limit': limit},
    );
    final results = (response.data as List).cast<Map<String, dynamic>>();
    return results.map(SearchExercise.fromJson).toList();
  }

  Future<SearchExercise?> findOrCreateExercise(String name) async {
    final response = await _http.get(
      ApiEndpoints.exerciseFindOrCreate,
      queryParameters: {'name': name.trim()},
    );
    if (response.statusCode == 200 && response.data != null) {
      return SearchExercise.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }
}
