/// Entidade para criação de sessões de treino
class SessionCreation {
  final String name;
  final int order;
  final List<String> muscles;
  final String? description;
  final List<SessionExerciseCreation>? exercises;

  const SessionCreation({
    required this.name,
    required this.order,
    this.muscles = const [],
    this.description,
    this.exercises,
  });

  factory SessionCreation.fromJson(Map<String, dynamic> json) {
    return SessionCreation(
      name: json['name'] as String,
      order: json['order'] as int? ?? 0,
      muscles: (json['muscles'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] as String?,
      exercises: (json['exercises'] as List?)
          ?.map(
            (e) => SessionExerciseCreation.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'order': order,
      'muscles': muscles,
      'description': description,
      'exercises': exercises?.map((e) => e.toJson()).toList(),
    };
  }
}

/// Entidade para criação de exercícios na sessão
class SessionExerciseCreation {
  final String exerciseId;
  final int order;
  final Map<String, dynamic>? config;

  const SessionExerciseCreation({
    required this.exerciseId,
    required this.order,
    this.config,
  });

  factory SessionExerciseCreation.fromJson(Map<String, dynamic> json) {
    return SessionExerciseCreation(
      exerciseId: json['exerciseId'] as String,
      order: json['order'] as int,
      config: json['config'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'exerciseId': exerciseId, 'order': order, 'config': config};
  }
}
