/// Configuração centralizada de todas as URLs e endpoints da API
/// Segue o Single Responsibility Principle - apenas URLs
import '../env.dart';

class ApiEndpoints {
  // Base URL (switchable via FLAVOR)
  static final String baseUrl = Env.apiBaseUrl;

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';

  // User endpoints
  static const String userProfile = '/user-profiles';
  static String userActiveRoutine(String routineId) =>
      '/user-profiles/active-routine/$routineId';

  // Routine endpoints
  static const String routines = '/routine';
  static String routine(String id) => '/routine/$id';
  static String routineById(String id) => '/routine/$id';
  static String routinesByUser(String userId) => '/routine/user/$userId';

  // Session endpoints
  static const String sessions = '/session';
  static String sessionById(String id) => '/session/$id';
  static String sessionsByRoutine(String routineId) =>
      '/session/routine/$routineId';
  static String removeExerciseFromSession(
    String sessionId,
    String exerciseId,
  ) => '/session/$sessionId/exercises/$exerciseId';

  // Exercise endpoints
  static const String exercises = '/exercises';
  static String exerciseSearch(String query, {int limit = 30}) =>
      '/exercises/search?q=$query&limit=$limit';
  static String exerciseById(String id) => '/exercises/$id';

  // Workout endpoints
  static const String workouts = '/workout';
  static String workoutById(String id) => '/workout/$id';
  static String workoutsByUser(String userId) => '/workout/user/$userId';
}

/// Configuração de parâmetros de query padrão
class ApiQueryParams {
  static const int defaultLimit = 30;
  static const int maxLimit = 100;
  static const String defaultSort = 'createdAt';
  static const String defaultOrder = 'desc';

  static Map<String, dynamic> pagination({
    int page = 1,
    int limit = defaultLimit,
  }) => {'page': page, 'limit': limit};

  static Map<String, dynamic> search({
    required String query,
    int limit = defaultLimit,
  }) => {'q': query, 'limit': limit};
}
