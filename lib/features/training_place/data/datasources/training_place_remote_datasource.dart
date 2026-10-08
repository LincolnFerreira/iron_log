import 'package:dio/dio.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/features/training_place/domain/entities/exercise_station.dart';
import 'package:iron_log/features/training_place/domain/entities/gym.dart';

class TrainingPlaceRemoteDataSource {
  TrainingPlaceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> upsertGym(
    Gym gym, {
    bool attachUnscopedStations = false,
  }) async {
    await _dio.post(
      ApiEndpoints.gyms,
      data: {
        'id': gym.id,
        'name': gym.name,
        if (attachUnscopedStations) 'attachUnscopedStations': true,
      },
    );
  }

  Future<void> renameGym(String id, String name) async {
    await _dio.patch(ApiEndpoints.gymById(id), data: {'name': name});
  }

  Future<ExerciseStation> upsertStation({
    required String id,
    required String exerciseId,
    required String nickname,
    String? gymId,
    String? brand,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.exerciseStations,
      data: {
        'id': id,
        'exerciseId': exerciseId,
        'nickname': nickname,
        if (gymId != null) 'gymId': gymId,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ExerciseStation(
        id: data['id']?.toString() ?? id,
        exerciseId: data['exerciseId']?.toString() ?? exerciseId,
        nickname: data['nickname']?.toString() ?? nickname,
        gymId: data['gymId']?.toString(),
        brand: data['brand']?.toString(),
        note: data['note']?.toString(),
      );
    }
    return ExerciseStation(
      id: id,
      exerciseId: exerciseId,
      nickname: nickname,
      gymId: gymId,
      brand: brand,
    );
  }

  Future<void> updateStation(
    String id, {
    String? nickname,
    bool archived = false,
  }) async {
    await _dio.patch(
      ApiEndpoints.exerciseStationById(id),
      data: {
        if (nickname != null) 'nickname': nickname,
        if (archived) 'archived': true,
      },
    );
  }
}
