/// DTO for workout history in routine
class RoutineWorkoutHistoryDto {
  final String id;
  final List<RoutineSerieLogDto> series;

  RoutineWorkoutHistoryDto({required this.id, required this.series});

  factory RoutineWorkoutHistoryDto.fromJson(Map<String, dynamic> json) {
    return RoutineWorkoutHistoryDto(
      id: json['id']?.toString() ?? '',
      series: ((json['series'] as List<dynamic>?) ?? [])
          .map((s) => RoutineSerieLogDto.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// DTO for a single series log in routine history
class RoutineSerieLogDto {
  final String id;
  final RoutineExerciseInfoDto exercise;

  RoutineSerieLogDto({required this.id, required this.exercise});

  factory RoutineSerieLogDto.fromJson(Map<String, dynamic> json) {
    return RoutineSerieLogDto(
      id: json['id']?.toString() ?? '',
      exercise: json['exercise'] != null
          ? RoutineExerciseInfoDto.fromJson(
              json['exercise'] as Map<String, dynamic>,
            )
          : RoutineExerciseInfoDto(id: '', name: 'Exercício'),
    );
  }
}

/// DTO for exercise info in routine history
class RoutineExerciseInfoDto {
  final String id;
  final String name;

  RoutineExerciseInfoDto({required this.id, required this.name});

  factory RoutineExerciseInfoDto.fromJson(Map<String, dynamic> json) {
    return RoutineExerciseInfoDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Exercício',
    );
  }
}
