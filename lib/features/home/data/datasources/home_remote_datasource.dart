import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/home/data/models/active_rest_dto.dart';
import 'package:iron_log/features/home/data/models/calendar_day_model.dart';
import 'package:iron_log/features/home/data/models/home_metrics_dto.dart';
import 'package:iron_log/features/home/data/models/rest_day_toggle_dto.dart';
import 'package:iron_log/features/home/domain/entities/home_metrics.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._http);

  final HttpService _http;

  Future<HomeMetrics?> fetchMetrics() async {
    final response = await _http.get(ApiEndpoints.meMetrics);
    if (response.statusCode != 200) return null;
    final dto = HomeMetricsDto.fromJson(
      response.data as Map<String, dynamic>,
    );
    return dto.toEntity();
  }

  Future<CalendarResponse> fetchWorkoutCalendar({int days = 14}) async {
    final response = await _http.get(ApiEndpoints.workoutCalendar(days: days));
    return CalendarResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> toggleRestDay(String isoDate) async {
    final response = await _http.post(
      ApiEndpoints.restDay,
      data: {'date': isoDate},
    );
    final dto = RestDayToggleDto.fromJson(
      response.data as Map<String, dynamic>,
    );
    return dto.active;
  }

  Future<RestDayEntity> createRestDay(CreateRestDayDto dto) async {
    final response = await _http.post(
      ApiEndpoints.restDay,
      data: dto.toJson(),
    );
    return RestDayEntity.fromJson(response.data as Map<String, dynamic>);
  }
}
