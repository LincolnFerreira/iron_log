import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/workout_day/presentation/providers/workout_timer_provider.dart';

/// Displays the elapsed time of the current workout session
/// Continues calculating time even if the app is in the background via timestamp-based calculation
class WorkoutTimer extends ConsumerWidget {
  const WorkoutTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsedTime = ref.watch(elapsedTimeProvider);

    return elapsedTime.when(
      data: (time) => Text(
        time,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
      loading: () => Text(
        '00:00',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
      error: (_, __) => Text(
        '00:00',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
