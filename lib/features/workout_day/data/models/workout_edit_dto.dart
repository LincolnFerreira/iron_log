/// DTO for deserializing a workout session for edit/load operations
class WorkoutEditDto {
  final String id;
  final String? routineId;
  final String? routineName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isManual;
  final List<WorkoutEditSerieLogDto> series;

  WorkoutEditDto({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startedAt,
    required this.endedAt,
    required this.isManual,
    required this.series,
  });

  /// Factory constructor to deserialize from API response.
  factory WorkoutEditDto.fromJson(Map<String, dynamic> json) {
    return WorkoutEditDto(
      id: json['id']?.toString() ?? '',
      routineId: json['routineId']?.toString(),
      routineName: (json['routine'] as Map<String, dynamic>?)?['name']
          ?.toString(),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      isManual: (json['isManual'] as bool?) ?? false,
      series: ((json['series'] as List<dynamic>?) ?? [])
          .map(
            (s) => WorkoutEditSerieLogDto.fromJson(s as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

/// DTO for a single series log in workout edit
class WorkoutEditSerieLogDto {
  final String id;
  final String? label;
  final String? tag;
  final double weight;
  final int reps;
  final int? rir;
  final int? restTime;
  final String? notes;

  WorkoutEditSerieLogDto({
    required this.id,
    required this.label,
    required this.tag,
    required this.weight,
    required this.reps,
    required this.rir,
    required this.restTime,
    required this.notes,
  });

  factory WorkoutEditSerieLogDto.fromJson(Map<String, dynamic> json) {
    return WorkoutEditSerieLogDto(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString(),
      tag: json['tag']?.toString(),
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      rir: (json['rir'] as num?)?.toInt(),
      restTime: (json['restTime'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
    );
  }
}
