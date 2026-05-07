import '../entities/routine.dart';
import '../entities/session_creation.dart';
import '../entities/routine_update.dart';
import '../repositories/routine_repository.dart';

class GetRoutinesUseCase {
  final RoutineRepository repository;

  GetRoutinesUseCase(this.repository);

  Future<List<Routine>> execute() async {
    // Lists are invariant in Dart: implementations may return `List<RoutineModel>`.
    // Normalize so every caller sees a true `List<Routine>` (avoids firstWhere/orElse runtime type errors).
    final list = await repository.getRoutines();
    return List<Routine>.from(list);
  }
}

class GetRoutineUseCase {
  final RoutineRepository repository;

  GetRoutineUseCase(this.repository);

  Future<Routine> execute(String id) async {
    return await repository.getRoutine(id);
  }
}

class CreateRoutineUseCase {
  final RoutineRepository repository;

  CreateRoutineUseCase(this.repository);

  Future<Routine> execute({
    required String name,
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  }) async {
    return await repository.createRoutine(
      name: name,
      division: division,
      isTemplate: isTemplate,
      sessions: sessions,
    );
  }
}

class UpdateRoutineUseCase {
  final RoutineRepository repository;

  UpdateRoutineUseCase(this.repository);

  Future<Routine> execute(String id, RoutineUpdate updates) async {
    return await repository.updateRoutine(id, updates);
  }
}

class DeleteRoutineUseCase {
  final RoutineRepository repository;

  DeleteRoutineUseCase(this.repository);

  Future<void> execute(String id) async {
    return await repository.deleteRoutine(id);
  }
}
