import 'package:iron_log/features/home/domain/entities/home_metrics.dart';

/// DTO for deserializing home metrics from API response
class HomeMetricsDto {
  final int workoutsCompleted;
  final int monthlyGoal;
  final int totalSeries;
  final int totalRoutines;

  HomeMetricsDto({
    required this.workoutsCompleted,
    required this.monthlyGoal,
    required this.totalSeries,
    required this.totalRoutines,
  });

  /// Factory constructor to deserialize from API response
  factory HomeMetricsDto.fromJson(Map<String, dynamic> json) {
    return HomeMetricsDto(
      workoutsCompleted: (json['workoutsCompleted'] as num?)?.toInt() ?? 0,
      monthlyGoal: (json['monthlyGoal'] as num?)?.toInt() ?? 12,
      totalSeries: (json['totalSeries'] as num?)?.toInt() ?? 0,
      totalRoutines: (json['totalRoutines'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert DTO to domain entity
  HomeMetrics toEntity() => HomeMetrics(
    workoutsCompleted: workoutsCompleted,
    monthlyGoal: monthlyGoal,
    totalSeries: totalSeries,
    totalRoutines: totalRoutines,
  );
}
