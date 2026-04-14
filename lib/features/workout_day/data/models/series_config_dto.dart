import 'api_field_names.dart';

/// Represents a single series/set from config.series[] array
class SeriesConfigDto {
  final String? label;
  final int? reps;
  final double? weight;
  final int? rir;
  final int? restTime;
  final String? notes;

  SeriesConfigDto({
    this.label,
    this.reps,
    this.weight,
    this.rir,
    this.restTime,
    this.notes,
  });

  factory SeriesConfigDto.fromJson(Map<String, dynamic> json) {
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

    return SeriesConfigDto(
      label:
          json[ApiFieldNames.label]?.toString() ??
          json[ApiFieldNames.tag]?.toString(),
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
