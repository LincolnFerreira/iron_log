/// Fixtures E2E resolvidos em runtime via API (conta já logada no device).
class E2eFixtures {
  static const password = String.fromEnvironment('E2E_PASSWORD');

  static String? _routineId;
  static String? _sessionId;
  static String? _exerciseNormalId;
  static String? _exerciseWarmupId;
  static String? _exerciseDropId;
  static String? _exerciseClusterId;

  /// Séries por exercício no seed (2 cada, ordem 1–4).
  static const setsPerExercise = 2;

  static bool get hasAuth => password.isNotEmpty;

  static String get routineId => _routineId ?? '';
  static String get sessionId => _sessionId ?? '';
  static String get exerciseNormalId => _exerciseNormalId ?? '';
  static String get exerciseWarmupId => _exerciseWarmupId ?? '';
  static String get exerciseDropId => _exerciseDropId ?? '';
  static String get exerciseClusterId => _exerciseClusterId ?? '';

  static bool get isConfigured =>
      routineId.isNotEmpty &&
      sessionId.isNotEmpty &&
      exerciseNormalId.isNotEmpty &&
      exerciseWarmupId.isNotEmpty &&
      exerciseDropId.isNotEmpty &&
      exerciseClusterId.isNotEmpty;

  static void applyResolved({
    required String routineId,
    required String sessionId,
    required String exerciseNormalId,
    required String exerciseWarmupId,
    required String exerciseDropId,
    required String exerciseClusterId,
  }) {
    _routineId = routineId;
    _sessionId = sessionId;
    _exerciseNormalId = exerciseNormalId;
    _exerciseWarmupId = exerciseWarmupId;
    _exerciseDropId = exerciseDropId;
    _exerciseClusterId = exerciseClusterId;
  }

  /// Índice global da 1ª série dentro do card (seed: 4 exercícios × 2 séries).
  static int seriesOffsetFor(String exerciseId) {
    final order = [
      exerciseNormalId,
      exerciseWarmupId,
      exerciseDropId,
      exerciseClusterId,
    ];
    final index = order.indexOf(exerciseId);
    if (index < 0) return 0;
    return index * setsPerExercise;
  }

  static void requireConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Fixtures E2E não resolvidos. Confira login + backend local no ar.',
      );
    }
  }
}
