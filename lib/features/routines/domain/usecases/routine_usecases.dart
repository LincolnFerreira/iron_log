import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

class GetRoutinesUseCase {
  final RoutineRepository repository;

  GetRoutinesUseCase(this.repository);

  Future<List<Routine>> execute() async {
    return await repository.getRoutines();
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
    List<Map<String, dynamic>>? sessions,
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

  Future<Routine> execute(String id, Map<String, dynamic> updates) async {
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
