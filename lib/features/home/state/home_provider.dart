import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/network/connectivity_utils.dart';
import 'package:iron_log/core/providers/sync_providers.dart';
import 'package:iron_log/features/home/state/workout_calendar_provider.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/domain/usecases/routine_usecases.dart';
import 'package:iron_log/features/routines/presentation/bloc/routine_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_service.dart';
import '../../../core/api/api_endpoints.dart';
import '../data/models/active_rest_dto.dart';
import 'package:iron_log/features/home/domain/entities/home_metrics.dart';
import 'package:iron_log/features/home/data/models/home_metrics_dto.dart';

class HomeState {
  final bool isLoading;
  final Routine? todaysRoutine;
  final Session? todaysSession;
  final String? error;
  final List<Routine> userRoutines;
  final HomeMetrics? metrics;

  /// Non-null when we want to inform the user about offline / cached data.
  final String? connectivityBanner;

  HomeState({
    this.isLoading = true,
    this.todaysRoutine,
    this.todaysSession,
    this.error,
    this.userRoutines = const [],
    this.metrics,
    this.connectivityBanner,
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
    String? connectivityBanner,
    bool clearConnectivityBanner = false,
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
      connectivityBanner: clearConnectivityBanner
          ? null
          : (connectivityBanner ?? this.connectivityBanner),
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final GetRoutinesUseCase _getRoutinesUseCase;
  final HttpService _httpService;
  final Connectivity _connectivity;
  bool _initialized = false;

  HomeNotifier(this._getRoutinesUseCase, this._httpService, this._connectivity)
    : super(HomeState());

  /// Initialize once. Calling this multiple times is safe.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _loadTodaysWorkout();
      _initialized = true;
    } catch (_) {
      // keep _initialized false so caller can retry initialize later
      rethrow;
    }
  }

  Future<void> _loadTodaysWorkout() async {
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearConnectivityBanner: true,
      );

      final online = await hasLikelyInternet(_connectivity);
      final connectivityBanner = online
          ? null
          : 'Sem conexão. Mostrando treinos salvos neste aparelho.';

      final routines =
          List<Routine>.from(await _getRoutinesUseCase.execute());

      HomeMetrics? metrics;
      if (online) {
        try {
          final metricsResponse = await _httpService.get(
            ApiEndpoints.meMetrics,
          );
          if (metricsResponse.statusCode == 200) {
            final metricsDto = HomeMetricsDto.fromJson(
              metricsResponse.data as Map<String, dynamic>,
            );
            metrics = metricsDto.toEntity();
          }
        } catch (_) {
          // Métricas são não-críticas, continua sem elas
        }
      }

      if (routines.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          userRoutines: [],
          metrics: metrics,
          connectivityBanner: online
              ? null
              : 'Sem conexão. Não há treinos salvos neste aparelho. Conecte-se online pelo menos uma vez.',
        );
        return;
      }

      Routine? active;
      for (final r in routines) {
        if (r.isActive) {
          active = r;
          break;
        }
      }
      final todaysRoutine = active ?? routines.first;

      final todaysSession = _getTodaysSession(todaysRoutine);

      state = state.copyWith(
        isLoading: false,
        todaysRoutine: todaysRoutine,
        todaysSession: todaysSession,
        userRoutines: routines,
        metrics: metrics,
        connectivityBanner: connectivityBanner,
      );
    } catch (e) {
      final online = await hasLikelyInternet(_connectivity);
      state = state.copyWith(
        isLoading: false,
        error: online
            ? 'Erro ao carregar treino do dia: $e'
            : 'Sem conexão. Não foi possível carregar treinos salvos.',
        clearConnectivityBanner: true,
      );
    }
  }

  Session? _getTodaysSession(Routine routine) {
    if (routine.sessions.isEmpty) return null;

    // Lógica simples: roda pelas sessões baseado no dia da semana
    final dayOfWeek = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final sessionIndex = (dayOfWeek - 1) % routine.sessions.length;

    // Ordena as sessões por ordem e pega a do dia
    final sortedSessions = List.of(routine.sessions)
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
  final getRoutines = ref.watch(getRoutinesUseCaseProvider);
  final httpService = ref.watch(httpServiceProvider);
  final connectivity = ref.watch(connectivityProvider);
  final notifier = HomeNotifier(getRoutines, httpService, connectivity);
  // Schedule a single initialization run after provider creation. This avoids
  // triggering loads on widget rebuilds such as opening/closing bottom sheets.
  Future.microtask(() => notifier.initialize());
  return notifier;
});

/// Provider para criar/atualizar um dia de descanso (rest day)
final createRestDayProvider =
    FutureProvider.family<RestDayEntity, CreateRestDayDto>((ref, dto) async {
      final authService = AuthService();
      authService.initialize();

      final response = await authService.post('/rest-day', data: dto.toJson());

      final restDay = RestDayEntity.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Invalida o provider de calendar para refrescar UI
      ref.invalidate(workoutCalendarProvider);

      return restDay;
    });
