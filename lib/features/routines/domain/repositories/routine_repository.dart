import '../entities/routine.dart';
import '../entities/session_creation.dart';
import '../entities/routine_update.dart';

abstract class RoutineRepository {
  Future<List<Routine>> getRoutines();
  Future<Routine> getRoutine(String id);
  Future<Routine> createRoutine({
    required String name,
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  });
  Future<Routine> updateRoutine(String id, RoutineUpdate updates);
  Future<void> deleteRoutine(String id);
}
