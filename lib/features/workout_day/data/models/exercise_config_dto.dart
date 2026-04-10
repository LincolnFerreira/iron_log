import 'api_field_names.dart';
import 'series_config_dto.dart';

/// Represents the 'config' JSON field from SessionExercise
class ExerciseConfigDto {
  final List<SeriesConfigDto> series;
  final String? variation;
  final int? reps;
  final double? weight;
  final int? rir;
  final int? restTime;
  final String? notes;

  ExerciseConfigDto({
    required this.series,
    this.variation,
    this.reps,
    this.weight,
    this.rir,
    this.restTime,
    this.notes,
  });

  factory ExerciseConfigDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ExerciseConfigDto(series: []);
    }

    // Parse series array
    final seriesData = json[ApiFieldNames.series];
    final seriesList = <SeriesConfigDto>[];

    if (seriesData is List) {
      seriesList.addAll(
        seriesData.whereType<Map<String, dynamic>>().map(
          SeriesConfigDto.fromJson,
        ),
      );
    }

    return ExerciseConfigDto(
      series: seriesList,
      variation: json[ApiFieldNames.variation]?.toString() ?? 'Traditional',
      reps: (json[ApiFieldNames.reps] as num?)?.toInt(),
      weight: (json[ApiFieldNames.weight] as num?)?.toDouble(),
      rir: (json[ApiFieldNames.rir] as num?)?.toInt(),
      restTime:
          (json[ApiFieldNames.restTime] as num?)?.toInt() ??
          (json[ApiFieldNames.rest] as num?)?.toInt(),
      notes: json[ApiFieldNames.notes]?.toString(),
    );
  }
}
