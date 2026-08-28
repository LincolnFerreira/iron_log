import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import 'package:iron_log/features/workout_history/data/datasources/workout_history_remote_datasource.dart';
import 'package:iron_log/features/workout_history/data/mappers/workout_history_mapper.dart';
import 'package:iron_log/features/workout_history/domain/repositories/workout_history_repository.dart';

class WorkoutHistoryRepositoryImpl implements WorkoutHistoryRepository {
  WorkoutHistoryRepositoryImpl({required WorkoutHistoryRemoteDataSource remote})
    : _remote = remote;

  final WorkoutHistoryRemoteDataSource _remote;

  @override
  Future<List<WorkoutHistory>> getWorkoutHistory() async {
    final dtos = await _remote.fetchWorkoutHistory();
    return dtos.map(WorkoutHistoryMapper.fromDto).toList();
  }

  @override
  Future<WorkoutHistory?> getLastWorkoutForRoutine(String routineId) async {
    try {
      final dto = await _remote.fetchLastWorkoutForRoutine(routineId);
      if (dto == null) return null;
      return WorkoutHistoryMapper.fromDto(dto);
    } catch (_) {
      return null;
    }
  }
}
