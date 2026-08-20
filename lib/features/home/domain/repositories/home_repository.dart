import 'package:iron_log/features/home/data/models/active_rest_dto.dart';
import 'package:iron_log/features/home/data/models/calendar_day_model.dart';
import 'package:iron_log/features/home/domain/entities/home_metrics.dart';

/// Fronteira de dados da Home (métricas, calendário, rest days).
///
/// Retorna modelos já usados pela UI (`CalendarResponse`, `RestDayEntity`) até
/// existirem entidades de domínio dedicadas — HTTP permanece só na data layer.
abstract class HomeRepository {
  Future<HomeMetrics?> fetchMetrics();

  Future<CalendarResponse> fetchWorkoutCalendar({int days = 14});

  /// POST /rest-day toggle; returns whether the day is now marked as rest.
  Future<bool> toggleRestDay(String isoDate);

  Future<RestDayEntity> createRestDay(CreateRestDayDto dto);
}
