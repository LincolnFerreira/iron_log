import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/http_service.dart';
import '../../../core/api/api_endpoints.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';

class HomeState {
  final bool isLoading;
  final Routine? todaysRoutine;
  final Session? todaysSession;
  final String? error;
  final List<Routine> userRoutines;

  HomeState({
    this.isLoading = true,
    this.todaysRoutine,
    this.todaysSession,
    this.error,
    this.userRoutines = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    Routine? todaysRoutine,
    Session? todaysSession,
    String? error,
    List<Routine>? userRoutines,
    bool clearError = false,
    bool clearTodaysRoutine = false,
    bool clearTodaysSession = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      todaysRoutine: clearTodaysRoutine
          ? null
          : (todaysRoutine ?? this.todaysRoutine),
      todaysSession: clearTodaysSession
          ? null
          : (todaysSession ?? this.todaysSession),
      error: clearError ? null : (error ?? this.error),
      userRoutines: userRoutines ?? this.userRoutines,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final HttpService _httpService;

  HomeNotifier(this._httpService) : super(HomeState()) {
    _loadTodaysWorkout();
  }

  Future<void> _loadTodaysWorkout() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // Usa URL centralizada
      final response = await _httpService.get(ApiEndpoints.routines);

      if (response.statusCode == 200) {
        final routinesData = response.data as List<dynamic>;
        final routines = routinesData
            .map((json) => Routine.fromJson(json as Map<String, dynamic>))
            .toList();

        if (routines.isEmpty) {
          state = state.copyWith(isLoading: false, userRoutines: []);
          return;
        }

        // Pega a primeira rotina (poderia ter lógica para escolher a ativa)
        final todaysRoutine = routines.first;

        // Determina qual sessão fazer hoje baseado no dia da semana
        final todaysSession = _getTodaysSession(todaysRoutine);

        state = state.copyWith(
          isLoading: false,
          todaysRoutine: todaysRoutine,
          todaysSession: todaysSession,
          userRoutines: routines,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Erro ao carregar rotinas',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar treino do dia: $e',
      );
    }
  }

  Session? _getTodaysSession(Routine routine) {
    if (routine.sessions.isEmpty) return null;

    // Lógica simples: roda pelas sessões baseado no dia da semana
    final dayOfWeek = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final sessionIndex = (dayOfWeek - 1) % routine.sessions.length;

    // Ordena as sessões por ordem e pega a do dia
    final sortedSessions = routine.sessions
      ..sort((a, b) => a.order.compareTo(b.order));
    return sortedSessions[sessionIndex];
  }

  Future<void> refresh() async {
    await _loadTodaysWorkout();
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final httpService = ref.read(httpServiceProvider);
  return HomeNotifier(httpService);
});
