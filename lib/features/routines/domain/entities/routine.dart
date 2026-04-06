class Routine {
  final String id;
  final String name;
  final String? division;
  final bool isTemplate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Session> sessions;

  const Routine({
    required this.id,
    required this.name,
    this.division,
    required this.isTemplate,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    required this.sessions,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      division: json['division']?.toString(),
      isTemplate: json['isTemplate'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      sessions:
          (json['sessions'] as List<dynamic>?)
              ?.map((e) => Session.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'division': division,
      'isTemplate': isTemplate,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sessions': sessions.map((e) => e.toJson()).toList(),
    };
  }
}

class Session {
  final String id;
  final String name;
  final int order;
  final List<String> muscles;
  final List<SessionExercise> exercises;

  const Session({
    required this.id,
    required this.name,
    required this.order,
    required this.muscles,
    required this.exercises,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      order: json['order'] as int? ?? 0,
      muscles: (json['muscles'] as List<dynamic>?)?.cast<String>() ?? [],
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((e) => SessionExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'muscles': muscles,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class SessionExercise {
  final String id;
  final String exerciseId;
  final Exercise exercise;
  final Map<String, dynamic>? config;

  const SessionExercise({
    required this.id,
    required this.exerciseId,
    required this.exercise,
    this.config,
  });

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    return SessionExercise(
      id: json['id']?.toString() ?? '',
      exerciseId: json['exerciseId']?.toString() ?? '',
      exercise: Exercise.fromJson(
        json['exercise'] as Map<String, dynamic>? ?? {},
      ),
      config: json['config'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'exercise': exercise.toJson(),
      'config': config,
    };
  }
}

class Exercise {
  final String id;
  final String name;
  final String? description;
  final String? primaryMuscle;
  final String? equipment;
  final List<String> tags;

  const Exercise({
    required this.id,
    required this.name,
    this.description,
    this.primaryMuscle,
    this.equipment,
    required this.tags,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      primaryMuscle: json['primaryMuscleId']?.toString(),
      equipment: json['equipmentId']?.toString(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'primaryMuscle': primaryMuscle,
      'equipment': equipment,
      'tags': tags,
    };
  }
}
