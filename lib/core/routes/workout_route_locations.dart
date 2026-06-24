import 'package:go_router/go_router.dart';
import 'package:iron_log/features/workout_day/presentation/pages/workout_day_screen.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import 'package:iron_log/features/workout_day/presentation/pages/workout_summary_screen.dart';

/// Canonical GoRouter paths for workout execution flows.
class WorkoutRouteLocations {
  static const execution = '/workout/execution';
  static const manual = '/workout/manual';
  static const summary = '/workout/summary';
  static const import = '/workout/import';
  static const importReviewPrefix = '/workout/import/review';

  static String importReview(String draftId) => '$importReviewPrefix/$draftId';
  static const editPrefix = '/workout/edit';
  static const resumePrefix = '/workout/resume';

  static String edit(String workoutId) => '$editPrefix/$workoutId';

  static String resume(String draftId) => '$resumePrefix/$draftId';

  static const summaryPath = summary;

  static String executionPath({
    required String routineId,
    required String sessionId,
    String? subtitle,
  }) {
    return Uri(
      path: execution,
      queryParameters: {
        'routineId': routineId,
        'sessionId': sessionId,
        if (subtitle != null) 'subtitle': subtitle,
      },
    ).toString();
  }

  static String manualPath({
    required DateTime manualDate,
    String? routineId,
    String? sessionId,
    String? subtitle,
  }) {
    return Uri(
      path: manual,
      queryParameters: {
        'date': manualDate.toIso8601String(),
        if (routineId != null) 'routineId': routineId,
        if (sessionId != null) 'sessionId': sessionId,
        if (subtitle != null) 'subtitle': subtitle,
      },
    ).toString();
  }

  static String editPath({
    required String workoutId,
    String? sessionId,
    String? subtitle,
    DateTime? manualDate,
    String? routineId,
  }) {
    return Uri(
      path: edit(workoutId),
      queryParameters: {
        if (sessionId != null) 'sessionId': sessionId,
        if (subtitle != null) 'subtitle': subtitle,
        if (manualDate != null) 'date': manualDate.toIso8601String(),
        if (routineId != null) 'routineId': routineId,
      },
    ).toString();
  }

  static WorkoutDayScreen screenFromState(GoRouterState state) {
    final path = state.uri.path;
    final query = state.uri.queryParameters;

    if (path.startsWith(resumePrefix)) {
      final draftId = state.pathParameters['draftId'];
      if (draftId == null || draftId.isEmpty) {
        throw ArgumentError('Missing draftId for workout resume route');
      }
      return WorkoutDayScreen.resume(draftId: draftId);
    }

    if (path.startsWith(editPrefix)) {
      final workoutId = state.pathParameters['id'];
      if (workoutId == null || workoutId.isEmpty) {
        throw ArgumentError('Missing workout id for workout edit route');
      }
      return WorkoutDayScreen.edit(
        workoutId: workoutId,
        sessionId: query['sessionId'],
        subtitle: query['subtitle'],
        routineId: query['routineId'],
        manualDate: _parseDate(query['date']),
      );
    }

    if (path == manual) {
      final manualDate = _parseDate(query['date']);
      if (manualDate == null) {
        throw ArgumentError('Missing date for manual workout route');
      }
      return WorkoutDayScreen.manual(
        manualDate: manualDate,
        routineId: query['routineId'],
        sessionId: query['sessionId'],
        subtitle: query['subtitle'],
      );
    }

    return WorkoutDayScreen.create(
      routineId: query['routineId'],
      sessionId: query['sessionId'],
      subtitle: query['subtitle'],
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static WorkoutSummaryScreen summaryScreenFromState(GoRouterState state) {
    final summary = state.extra;
    if (summary is! WorkoutSummary) {
      throw ArgumentError(
        'Workout summary route requires WorkoutSummary in GoRouterState.extra',
      );
    }
    return WorkoutSummaryScreen(workoutSummary: summary);
  }
}
