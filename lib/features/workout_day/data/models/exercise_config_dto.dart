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

    // Helper function para converter valores numéricos com debug
    int? parseToInt(dynamic value, String fieldName) {
      try {
        if (value == null) return null;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.parse(value);
        print('⚠️ Warning: $fieldName = $value (type: ${value.runtimeType}) não pôde ser parseado como int');
        return null;
      } catch (e) {
        print('❌ Erro ao parsear $fieldName = $value: $e');
        return null;
      }
    }

    double? parseToDouble(dynamic value, String fieldName) {
      try {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.parse(value);
        print('⚠️ Warning: $fieldName = $value (type: ${value.runtimeType}) não pôde ser parseado como double');
        return null;
      } catch (e) {
        print('❌ Erro ao parsear $fieldName = $value (${value.runtimeType}): $e');
        return null;
      }
    }

    return ExerciseConfigDto(
      series: seriesList,
      variation: json[ApiFieldNames.variation]?.toString() ?? 'Traditional',
      reps: parseToInt(json[ApiFieldNames.reps], 'reps'),
      weight: parseToDouble(json[ApiFieldNames.weight], 'weight'),
      rir: parseToInt(json[ApiFieldNames.rir], 'rir'),
      restTime:
          parseToInt(json[ApiFieldNames.restTime], 'restTime') ??
          parseToInt(json[ApiFieldNames.rest], 'rest'),
      notes: json[ApiFieldNames.notes]?.toString(),
    );
  }
}
