/// Constantes de endpoints da API
/// Centraliza todas as URLs usadas no projeto para facilitar manutenção
class ApiEndpoints {
  // Base
  static const String routines = '/routines';

  // Exercícios
  static const String exerciseSearch = '/exercises/search';
  static const String exercises = '/exercises';
  // Find or create via backend (Gemini-assisted)
  static const String exerciseFindOrCreate = '/exercises/find-or-create';

  // Workouts
  static const String workouts = '/workouts';
  static const String workoutSessions = '/workout-sessions';

  // Auth (caso necessário para outros endpoints)
  static const String auth = '/auth';
  static const String authMe = '/auth/me';
  static const String authProfile = '/auth/profile';

  // Construtor privado para evitar instanciação
  ApiEndpoints._();
}
