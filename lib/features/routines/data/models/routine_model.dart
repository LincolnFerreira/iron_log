import '../../domain/entities/routine.dart';

class RoutineModel extends Routine {
  const RoutineModel({
    required super.id,
    required super.userId,
    required super.name,
    super.division,
    required super.isTemplate,
    required super.createdAt,
    required super.updatedAt,
    required super.sessions,
    super.isActive,
    super.version,
    super.pendingSync,
    super.syncedAt,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      division: json['division']?.toString(),
      isTemplate: json['isTemplate'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      version: json['version'] as int?,
      pendingSync: json['pendingSync'] as bool?,
      syncedAt: json['syncedAt'] != null
          ? DateTime.tryParse(json['syncedAt']?.toString() ?? '')
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      sessions:
          (json['sessions'] as List<dynamic>?)
              ?.map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'division': division,
      'isTemplate': isTemplate,
      'isActive': isActive,
      'version': version,
      'pendingSync': pendingSync,
      'syncedAt': syncedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sessions': sessions.map((e) => (e as SessionModel).toJson()).toList(),
    };
  }
}

class SessionModel extends Session {
  const SessionModel({
    required super.id,
    required super.name,
    required super.order,
    required super.muscles,
    required super.exercises,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      order: json['order'] as int? ?? 0,
      muscles: (json['muscles'] as List<dynamic>?)?.cast<String>() ?? [],
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map(
                (e) => SessionExerciseModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'muscles': muscles,
      'exercises': exercises
          .map((e) => (e as SessionExerciseModel).toJson())
          .toList(),
    };
  }
}

class SessionExerciseModel extends SessionExercise {
  const SessionExerciseModel({
    required super.id,
    required super.exerciseId,
    required super.exercise,
    super.config,
  });

  factory SessionExerciseModel.fromJson(Map<String, dynamic> json) {
    return SessionExerciseModel(
      id: json['id']?.toString() ?? '',
      exerciseId: json['exerciseId']?.toString() ?? '',
      exercise: ExerciseModel.fromJson(
        json['exercise'] as Map<String, dynamic>? ?? {},
      ),
      config: json['config'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'exercise': (exercise as ExerciseModel).toJson(),
      'config': config,
    };
  }
}

class ExerciseModel extends Exercise {
  const ExerciseModel({
    required super.id,
    required super.name,
    super.description,
    super.primaryMuscle,
    super.equipment,
    required super.tags,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      primaryMuscle: json['primaryMuscleId']?.toString(),
      equipment: json['equipmentId']?.toString(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
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
