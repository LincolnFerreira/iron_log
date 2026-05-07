import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/home/domain/entities/home_metrics.dart';

import '../molecules/greeting_header.dart';
import '../molecules/active_sequence_card.dart';
import '../molecules/mini_calendar_strip.dart';
import '../molecules/todays_workout_card.dart';
import '../organisms/workout_quick_actions_grid.dart';
import '../organisms/your_month_section.dart';

class HomeTemplate extends StatelessWidget {
  final String userName;
  final VoidCallback onStartWorkout;
  final VoidCallback onChangeWorkout;
  final VoidCallback onQuickCreate;
  final VoidCallback? onRetryWorkout;
  final VoidCallback? onAvatarTap;
  final Future<void> Function()? onRefresh;
  final String? imageUrl;
  final Routine? todaysRoutine;
  final Session? todaysSession;
  final bool isLoadingWorkout;
  final String? error;
  final HomeMetrics? metrics;
  final List<Session> routineSessions;
  final void Function(Session)? onSelectSession;
  final int streak;
  final String? connectivityBanner;

  const HomeTemplate({
    super.key,
    this.imageUrl,
    required this.userName,
    required this.onStartWorkout,
    required this.onChangeWorkout,
    required this.onQuickCreate,
    this.onRetryWorkout,
    this.onAvatarTap,
    this.onRefresh,
    this.todaysRoutine,
    this.todaysSession,
    this.isLoadingWorkout = false,
    this.error,
    this.metrics,
    this.routineSessions = const [],
    this.onSelectSession,
    this.streak = 0,
    this.connectivityBanner,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Active sequence card
            // Greeting header with date
            GreetingHeader(
              name: userName,
              title: 'BOM TREINO,',
              imageUrl: imageUrl,
              onAvatarTap: onAvatarTap,
            ),
            if (connectivityBanner != null) _OfflineInfoBanner(message: connectivityBanner!),
            if (error != null) _HomeInlineError(message: error!),
            ActiveSequenceCard(streak: streak),
            // Mini calendário — últimos 14 dias (bloco consistência)
            const MiniCalendarStrip(),
            Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getWeekdayAbbr()} • ${DateTime.now().day} DE ${_getMonthName()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                // Today's workout card with exercise chips and start button
                TodaysWorkoutCard(
                  todaysRoutine: todaysRoutine,
                  todaysSession: todaysSession,
                  isLoading: isLoadingWorkout,
                  onStartWorkout: onStartWorkout,
                  onNoWorkoutTap: onChangeWorkout,
                  sessions: routineSessions,
                  onSelectSession: onSelectSession,
                ),
              ],
            ),
            // Quick actions grid
            WorkoutQuickActionsGrid(
              onMyRoutinesTap: onChangeWorkout,
              onNewRoutinesTap: () => context.push('/routines'),
              onQuickCreateTap: onQuickCreate,
            ),
            // Your month section with metrics and monthly goal progress
            YourMonthSection(
              workoutsCompleted: metrics?.workoutsCompleted ?? 0,
              monthlyGoal: metrics?.monthlyGoal ?? 12,
              totalSeries: metrics?.totalSeries ?? 0,
              totalRoutines: metrics?.totalRoutines ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekdayAbbr() {
    const weekdays = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];
    return weekdays[DateTime.now().weekday - 1];
  }

  String _getMonthName() {
    const months = [
      'JANEIRO',
      'FEVEREIRO',
      'MARÇO',
      'ABRIL',
      'MAIO',
      'JUNHO',
      'JULHO',
      'AGOSTO',
      'SETEMBRO',
      'OUTUBRO',
      'NOVEMBRO',
      'DEZEMBRO',
    ];
    return months[DateTime.now().month - 1];
  }
}

class _OfflineInfoBanner extends StatelessWidget {
  final String message;

  const _OfflineInfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.wifi_off_outlined, size: 20, color: scheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeInlineError extends StatelessWidget {
  final String message;

  const _HomeInlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 20, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
