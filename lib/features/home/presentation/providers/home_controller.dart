import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/network/connectivity_utils.dart';
import 'package:iron_log/core/providers/sync_providers.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/home/data/models/home_metrics_dto.dart';
import 'package:iron_log/features/home/domain/entities/home_metrics.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/domain/usecases/routine_usecases.dart';
import 'package:iron_log/features/routines/presentation/providers/routine_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'home_state.dart';

part 'home_controller.g.dart';

@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {
  bool _initialized = false;

  @override
  HomeState build() {
    Future.microtask(initialize);
    return const HomeState();
  }

  GetRoutinesUseCase get _getRoutinesUseCase =>
      ref.read(getRoutinesUseCaseProvider);

  HttpService get _httpService => ref.read(httpServiceProvider);

  Connectivity get _connectivity => ref.read(connectivityProvider);

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _loadTodaysWorkout();
      _initialized = true;
    } catch (_) {
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

      final routines = List<Routine>.from(await _getRoutinesUseCase.execute());

      HomeMetrics? metrics;
      if (online) {
        try {
          final metricsResponse = await _httpService.get(ApiEndpoints.meMetrics);
          if (metricsResponse.statusCode == 200) {
            final metricsDto = HomeMetricsDto.fromJson(
              metricsResponse.data as Map<String, dynamic>,
            );
            metrics = metricsDto.toEntity();
          }
        } catch (_) {
          // Métricas são não-críticas
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

    final dayOfWeek = DateTime.now().weekday;
    final sessionIndex = (dayOfWeek - 1) % routine.sessions.length;
    final sortedSessions = List.of(routine.sessions)
      ..sort((a, b) => a.order.compareTo(b.order));
    return sortedSessions[sessionIndex];
  }

  void selectSession(Session session) {
    state = state.copyWith(todaysSession: session);
  }

  Future<void> refresh() async {
    await _loadTodaysWorkout();
  }
}

/// Alias de compatibilidade — preferir [homeControllerProvider] em código novo.
final homeProvider = homeControllerProvider;
