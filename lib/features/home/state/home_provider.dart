import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/http_service.dart';
import '../../../core/api/api_endpoints.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/home/domain/entities/home_metrics.dart';

class HomeState {
  final bool isLoading;
  final Routine? todaysRoutine;
  final Session? todaysSession;
  final String? error;
  final List<Routine> userRoutines;
  final HomeMetrics? metrics;

  HomeState({
    this.isLoading = true,
    this.todaysRoutine,
    this.todaysSession,
    this.error,
    this.userRoutines = const [],
    this.metrics,
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
    HomeMetrics? metrics,
    bool clearMetrics = false,
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
      metrics: clearMetrics ? null : (metrics ?? this.metrics),
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

        // Busca métricas em paralelo
        HomeMetrics? metrics;
        try {
          final metricsResponse = await _httpService.get(
            ApiEndpoints.meMetrics,
          );
          if (metricsResponse.statusCode == 200) {
            metrics = HomeMetrics.fromJson(
              metricsResponse.data as Map<String, dynamic>,
            );
          }
        } catch (_) {
          // Métricas são não-críticas, continua sem elas
        }

        if (routines.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            userRoutines: [],
            metrics: metrics,
          );
          return;
        }

        // Prefere a rotina marcada como ativa; caso nenhuma esteja,
        // usa a primeira como fallback (comportamento anterior).
        final todaysRoutine = routines.firstWhere(
          (r) => r.isActive,
          orElse: () => routines.first,
        );

        // Determina qual sessão fazer hoje baseado no dia da semana
        final todaysSession = _getTodaysSession(todaysRoutine);

        state = state.copyWith(
          isLoading: false,
          todaysRoutine: todaysRoutine,
          todaysSession: todaysSession,
          userRoutines: routines,
          metrics: metrics,
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

  /// Troca a sessão que será iniciada, sem chamar a API.
  void selectSession(Session session) {
    state = state.copyWith(todaysSession: session);
  }

  Future<void> refresh() async {
    await _loadTodaysWorkout();
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final httpService = ref.read(httpServiceProvider);
  return HomeNotifier(httpService);
});
