import '../entities/routine.dart';
import '../repositories/session_repository.dart';

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
