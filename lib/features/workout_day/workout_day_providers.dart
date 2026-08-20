import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/workout_day/data/datasources/workout_day_remote_datasource.dart';
import 'package:iron_log/features/workout_day/data/repositories/workout_day_repository_impl.dart';
import 'package:iron_log/features/workout_day/domain/repositories/workout_day_repository.dart';

final workoutDayRemoteDataSourceProvider =
    Provider<WorkoutDayRemoteDataSource>((ref) {
      return WorkoutDayRemoteDataSource(ref.read(httpServiceProvider));
    });

final workoutDayRepositoryProvider = Provider<WorkoutDayRepository>((ref) {
  return WorkoutDayRepositoryImpl(
    ref.read(workoutDayRemoteDataSourceProvider),
  );
});
