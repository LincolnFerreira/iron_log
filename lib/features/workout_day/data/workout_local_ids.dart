/// IDs gerados no cliente / fila local de workout.
abstract final class WorkoutLocalIds {
  static bool isLocalSession(String id) => id.startsWith('local_');

  static bool isQueuedOutbox(String id) => id.startsWith('queued_');

  /// Sessão criada offline no “Iniciar treino” (sem POST ainda).
  static String newLocalSessionId() =>
      'local_${DateTime.now().millisecondsSinceEpoch}';

  static String newOutboxRowId() => 'ob_${DateTime.now().microsecondsSinceEpoch}';
}
