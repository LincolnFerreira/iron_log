/// DTO for deserializing a single workout session from the API.
class WorkoutHistoryDto {
  final String id;
  final String? routineId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<SerieLogDto> series;
  final RoutineInfoDto? routine;

  WorkoutHistoryDto({
    required this.id,
    required this.routineId,
    required this.startedAt,
    required this.endedAt,
    required this.series,
    required this.routine,
  });

  /// Factory constructor to deserialize from API response.
  factory WorkoutHistoryDto.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryDto(
      id: json['id']?.toString() ?? '',
      routineId: json['routineId']?.toString(),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      series: ((json['series'] as List<dynamic>?) ?? [])
          .map((s) => SerieLogDto.fromJson(s as Map<String, dynamic>))
          .toList(),
      routine: json['routine'] != null
          ? RoutineInfoDto.fromJson(json['routine'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// DTO for exercise information in a series.
class ExerciseInfoDto {
  final String id;
  final String name;

  ExerciseInfoDto({required this.id, required this.name});

  factory ExerciseInfoDto.fromJson(Map<String, dynamic> json) {
    return ExerciseInfoDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Exercício',
    );
  }
}

/// DTO for routine information in a workout history.
class RoutineInfoDto {
  final String id;
  final String name;

  RoutineInfoDto({required this.id, required this.name});

  factory RoutineInfoDto.fromJson(Map<String, dynamic> json) {
    return RoutineInfoDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Treino',
    );
  }
}

/// DTO for session exercise information.
class SessionExerciseInfoDto {
  final SessionInfoDto? session;

  SessionExerciseInfoDto({required this.session});

  factory SessionExerciseInfoDto.fromJson(Map<String, dynamic> json) {
    return SessionExerciseInfoDto(
      session: json['session'] != null
          ? SessionInfoDto.fromJson(json['session'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// DTO for session information.
class SessionInfoDto {
  final String id;
  final String name;

  SessionInfoDto({required this.id, required this.name});

  factory SessionInfoDto.fromJson(Map<String, dynamic> json) {
    return SessionInfoDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sessão',
    );
  }
}

/// DTO for a single series log.
class SerieLogDto {
  final String id;
  final double weight;
  final int reps;
  final ExerciseInfoDto exercise;
  final SessionExerciseInfoDto? sessionExercise;

  SerieLogDto({
    required this.id,
    required this.weight,
    required this.reps,
    required this.exercise,
    required this.sessionExercise,
  });

  factory SerieLogDto.fromJson(Map<String, dynamic> json) {
    return SerieLogDto(
      id: json['id']?.toString() ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      exercise: json['exercise'] != null
          ? ExerciseInfoDto.fromJson(json['exercise'] as Map<String, dynamic>)
          : ExerciseInfoDto(id: '', name: 'Exercício'),
      sessionExercise: json['sessionExercise'] != null
          ? SessionExerciseInfoDto.fromJson(
              json['sessionExercise'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
