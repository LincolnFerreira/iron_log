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
    return SeriesConfigDto(
      label:
          json[ApiFieldNames.label]?.toString() ??
          json[ApiFieldNames.tag]?.toString(),
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
