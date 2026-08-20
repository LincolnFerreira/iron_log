import 'package:iron_log/features/home/data/datasources/home_remote_datasource.dart';
import 'package:iron_log/features/home/data/models/active_rest_dto.dart';
import 'package:iron_log/features/home/data/models/calendar_day_model.dart';
import 'package:iron_log/features/home/domain/entities/home_metrics.dart';
import 'package:iron_log/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote);

  final HomeRemoteDataSource _remote;

  @override
  Future<HomeMetrics?> fetchMetrics() => _remote.fetchMetrics();

  @override
  Future<CalendarResponse> fetchWorkoutCalendar({int days = 14}) =>
      _remote.fetchWorkoutCalendar(days: days);

  @override
  Future<bool> toggleRestDay(String isoDate) => _remote.toggleRestDay(isoDate);

  @override
  Future<RestDayEntity> createRestDay(CreateRestDayDto dto) =>
      _remote.createRestDay(dto);
}
