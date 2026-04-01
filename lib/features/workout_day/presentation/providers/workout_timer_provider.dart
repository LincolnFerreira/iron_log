import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Provider that manages the workout session timer
/// Stores the start timestamp and provides elapsed time calculation
final workoutTimerProvider =
    StateNotifierProvider<WorkoutTimerNotifier, DateTime?>((ref) {
      return WorkoutTimerNotifier();
    });

/// Provides the formatted elapsed time (MM:SS) that rebuilds every second
final elapsedTimeProvider = StreamProvider<String>((ref) async* {
  final startTime = ref.watch(workoutTimerProvider);

  if (startTime == null) {
    yield '00:00';
    return;
  }

  while (true) {
    final elapsed = DateTime.now().difference(startTime);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    yield '$minutes:$seconds';

    // Update every second
    await Future.delayed(const Duration(seconds: 1));
  }
});

class WorkoutTimerNotifier extends StateNotifier<DateTime?> {
  WorkoutTimerNotifier() : super(null);

  /// Starts the timer from current time
  void startTimer() {
    state = DateTime.now();
  }

  /// Resets the timer
  void resetTimer() {
    state = null;
  }

  /// Gets the elapsed duration since timer started
  Duration? getElapsedDuration() {
    if (state == null) return null;
    return DateTime.now().difference(state!);
  }
}
