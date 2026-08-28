import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/domain/entities/routine_update.dart';
import 'package:iron_log/features/routines/domain/entities/session_creation.dart';

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
  Future<void> setActiveRoutine(String routineId);
}
