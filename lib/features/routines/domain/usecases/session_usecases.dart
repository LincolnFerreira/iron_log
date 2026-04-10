import '../entities/routine.dart';
import '../repositories/session_repository.dart';
import '../../data/models/session_exercise_update_dto.dart';

class CreateSessionUseCase {
  final SessionRepository repository;

  CreateSessionUseCase(this.repository);

  Future<Session> execute({
    required String routineId,
    required String name,
    required int order,
    List<String> muscles = const [],
  }) async {
    return await repository.createSession(
      routineId: routineId,
      name: name,
      order: order,
      muscles: muscles,
    );
  }
}

class UpdateSessionUseCase {
  final SessionRepository repository;

  UpdateSessionUseCase(this.repository);

  Future<Session> execute(
    String id, {
    String? name,
    int? order,
    List<String>? muscles,
  }) async {
    return await repository.updateSession(
      id,
      name: name,
      order: order,
      muscles: muscles,
    );
  }
}

class DeleteSessionUseCase {
  final SessionRepository repository;

  DeleteSessionUseCase(this.repository);

  Future<void> execute(String id) async {
    return await repository.deleteSession(id);
  }
}

class UpdateSessionExercisesUseCase {
  final SessionRepository repository;

  UpdateSessionExercisesUseCase(this.repository);

  Future<Session> execute(
    String sessionId,
    List<SessionExerciseUpdateDto> exercises,
  ) async {
    // Convert DTOs to Maps for repository if needed
    // OR repository can be refactored to work with DTOs directly
    final exerciseMaps = exercises.map((e) => e.toJson()).toList();
    return await repository.updateSessionExercises(sessionId, exerciseMaps);
  }
}

class RemoveExerciseFromSessionUseCase {
  final SessionRepository repository;

  RemoveExerciseFromSessionUseCase(this.repository);

  Future<void> execute(String sessionId, String exerciseId) async {
    return await repository.removeExerciseFromSession(sessionId, exerciseId);
  }
}
