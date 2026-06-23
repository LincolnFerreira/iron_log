import 'package:dio/dio.dart';
import 'package:iron_log/core/api/api_endpoints.dart';

import '../models/workout_history_dto.dart';

abstract class WorkoutHistoryRemoteDataSource {
  Future<List<WorkoutHistoryDto>> fetchWorkoutHistory();

  Future<WorkoutHistoryDto?> fetchLastWorkoutForRoutine(String routineId);
}

class WorkoutHistoryRemoteDataSourceImpl
    implements WorkoutHistoryRemoteDataSource {
  WorkoutHistoryRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<WorkoutHistoryDto>> fetchWorkoutHistory() async {
    final response = await _dio.get(ApiEndpoints.workouts);
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map(
          (item) =>
              WorkoutHistoryDto.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<WorkoutHistoryDto?> fetchLastWorkoutForRoutine(String routineId) async {
    final response = await _dio.get(
      ApiEndpoints.routineWorkouts(routineId),
      queryParameters: {'take': 1},
    );
    final list = response.data as List<dynamic>? ?? [];
    if (list.isEmpty) return null;
    return WorkoutHistoryDto.fromJson(list.first as Map<String, dynamic>);
  }
}
