import '../entities/routine.dart';

abstract class RoutineRepository {
  Future<List<Routine>> getRoutines();
  Future<Routine> getRoutine(String id);
  Future<Routine> createRoutine({
    required String name,
    String? division,
    bool isTemplate = false,
    List<Map<String, dynamic>>? sessions,
  });
  Future<Routine> updateRoutine(String id, Map<String, dynamic> updates);
  Future<void> deleteRoutine(String id);
}
