import 'package:iron_log/features/home/domain/entities/home_metrics.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';

class HomeState {
  final bool isLoading;
  final Routine? todaysRoutine;
  final Session? todaysSession;
  final String? error;
  final List<Routine> userRoutines;
  final HomeMetrics? metrics;

  /// Non-null when we want to inform the user about offline / cached data.
  final String? connectivityBanner;

  const HomeState({
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
