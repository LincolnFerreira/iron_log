import '../entities/routine.dart';
import '../../data/models/session_exercise_update_dto.dart';

abstract class SessionRepository {
  Future<Session> createSession({
    required String routineId,
    required String name,
    required int order,
    List<String> muscles = const [],
  });
  Future<Session> updateSession(
    String id, {
    String? name,
    int? order,
    List<String>? muscles,
  });
  Future<void> deleteSession(String id);

  /// Atualizar exercícios da sessão
  Future<Session> updateSessionExercises(
    String sessionId,
    List<SessionExerciseUpdateDto> exercises,
  );

  /// Remover exercício específico da sessão
  Future<void> removeExerciseFromSession(String sessionId, String exerciseId);
}
