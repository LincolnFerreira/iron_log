import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/home/presentation/providers/home_header_providers.dart';
import 'package:iron_log/features/home/presentation/providers/home_provider.dart';
import 'package:iron_log/features/home/presentation/providers/workout_calendar_provider.dart';
import 'package:iron_log/features/workout_day/presentation/providers/workout_draft_providers.dart';

import '../molecules/greeting_header.dart';
import '../molecules/active_sequence_card.dart';
import '../molecules/mini_calendar_strip.dart';
import '../molecules/todays_workout_card.dart';
import '../organisms/workout_quick_actions_grid.dart';
import '../organisms/your_month_section.dart';

/// Template da Home: callbacks na page; estado via Consumers isolados (T073).
class HomeTemplate extends StatelessWidget {
  final VoidCallback onStartWorkout;
  final VoidCallback onChangeWorkout;
  final VoidCallback onQuickCreate;
  final VoidCallback? onRetryWorkout;
  final VoidCallback? onAvatarTap;
  final Future<void> Function()? onRefresh;
  final void Function(Session)? onSelectSession;
  final VoidCallback? onContinueWorkout;

  const HomeTemplate({
    super.key,
    required this.onStartWorkout,
    required this.onChangeWorkout,
    required this.onQuickCreate,
    this.onRetryWorkout,
    this.onAvatarTap,
    this.onRefresh,
    this.onSelectSession,
    this.onContinueWorkout,
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
            Consumer(
              builder: (context, ref, _) {
                final name = ref.watch(homeGreetingNameProvider);
                final imageUrl = ref.watch(homeUserPhotoUrlProvider);
                return GreetingHeader(
                  name: name,
                  title: 'BOM TREINO,',
                  imageUrl: imageUrl,
                  onAvatarTap: onAvatarTap,
                );
              },
            ),
            Consumer(
              builder: (context, ref, _) {
                final banner = ref.watch(
                  homeProvider.select((s) => s.connectivityBanner),
                );
                if (banner == null) return const SizedBox.shrink();
                return _OfflineInfoBanner(message: banner);
              },
            ),
            Consumer(
              builder: (context, ref, _) {
                final error = ref.watch(homeProvider.select((s) => s.error));
                if (error == null) return const SizedBox.shrink();
                return _HomeInlineError(message: error);
              },
            ),
            Consumer(
              builder: (context, ref, _) {
                final streak = ref.watch(workoutStreakProvider);
                return ActiveSequenceCard(streak: streak);
              },
            ),
            const MiniCalendarStrip(),
            Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getWeekdayAbbr()} • ${DateTime.now().day} DE ${_getMonthName()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final homeState = ref.watch(homeProvider);
                    final activeDraft =
                        ref.watch(activeWorkoutDraftProvider).valueOrNull;
                    return TodaysWorkoutCard(
                      todaysRoutine: homeState.todaysRoutine,
                      todaysSession: homeState.todaysSession,
                      isLoading: homeState.isLoading,
                      onStartWorkout: onStartWorkout,
                      onNoWorkoutTap: onChangeWorkout,
                      sessions: homeState.todaysRoutine?.sessions ?? [],
                      onSelectSession: onSelectSession,
                      activeDraft: activeDraft,
                      onContinueWorkout: activeDraft != null
                          ? onContinueWorkout
                          : null,
                    );
                  },
                ),
              ],
            ),
            WorkoutQuickActionsGrid(
              onMyRoutinesTap: onChangeWorkout,
              onNewRoutinesTap: () => context.push('/routines'),
              onQuickCreateTap: onQuickCreate,
            ),
            Consumer(
              builder: (context, ref, _) {
                final metrics = ref.watch(
                  homeProvider.select((s) => s.metrics),
                );
                return YourMonthSection(
                  workoutsCompleted: metrics?.workoutsCompleted ?? 0,
                  monthlyGoal: metrics?.monthlyGoal ?? 12,
                  totalSeries: metrics?.totalSeries ?? 0,
                  totalRoutines: metrics?.totalRoutines ?? 0,
                );
              },
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
            Icon(
              Icons.wifi_off_outlined,
              size: 20,
              color: scheme.onSecondaryContainer,
            ),
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
