import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/workout_summary.dart';
import '../../data/services/workout_log_service.dart';
import '../mappers/workout_mapper.dart';
import '../../domain/workout_mode.dart';
import '../providers/workout_day_provider.dart';
import '../providers/workout_timer_provider.dart';

class FinishResult {
  final bool success;
  final WorkoutSummary? summary;
  final String? error;
  final bool needDuration;
  final bool needSessionSelection;

  FinishResult({
    required this.success,
    this.summary,
    this.error,
    this.needDuration = false,
    this.needSessionSelection = false,
  });
}

final workoutControllerProvider =
    StateNotifierProvider<WorkoutController, AsyncValue<void>>(
      (ref) => WorkoutController(ref),
    );

class WorkoutController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final WorkoutLogService _service = WorkoutLogService();

  WorkoutController(this.ref) : super(const AsyncData(null));

  void startWorkout() {
    ref.read(workoutTimerProvider.notifier).startTimer();
    // no state change required here
  }

  Future<FinishResult> finishWorkout({
    required WorkoutMode mode,
    required List<WorkoutExercise> exercises,
    String? routineId,
    String? sessionId,
    String? workoutId,
    DateTime? selectedDate,
    DateTime? timerStartTime,
    Duration? manualDuration,
    bool clearCacheOnSuccess = true,
  }) async {
    try {
      // Debug tracing: log all input parameters and relevant provider state
      if (kDebugMode) {
        try {
          print('finishWorkout called - mode: $mode');
          print(' - exercisesCount: ${exercises.length}');
          print(' - exercises: ${exercises.map((e) => e.toString()).toList()}');
          print(' - routineId: $routineId');
          print(' - sessionId: $sessionId');
          print(' - workoutId: $workoutId');
          print(' - selectedDate: $selectedDate');
          print(' - timerStartTime: $timerStartTime');
          print(' - manualDuration: $manualDuration');

          final originalDur = ref.read(workoutOriginalDurationProvider);
          print(' - workoutOriginalDurationProvider: $originalDur');

          final providerState = ref.read(workoutDayExercisesProvider);
          print(' - workoutDayExercisesProvider: $providerState');

          final timerState = ref.read(workoutTimerProvider);
          print(' - workoutTimerProvider startTime: $timerState');
        } catch (logErr) {
          print(
            'Warning: failed while logging debug info in finishWorkout: $logErr',
          );
        }
      }

      state = const AsyncValue.loading();

      final now = DateTime.now();

      // Decide times
      DateTime startedAt;
      DateTime endedAt;

      if (selectedDate != null) {
        final existingDur = ref.read(workoutOriginalDurationProvider);
        final Duration? durationToUse = existingDur ?? manualDuration;
        if (durationToUse == null) {
          state = const AsyncValue.data(null);
          return FinishResult(success: false, needDuration: true);
        }
        startedAt = selectedDate;
        endedAt = startedAt.add(durationToUse);
      } else {
        startedAt = timerStartTime ?? now;
        endedAt = now;
      }

      // If there's a session and NOT in edit mode, persist session exercises
      // (edit mode uses updateWorkout for existing WorkoutSession)
      if (sessionId != null &&
          sessionId.isNotEmpty &&
          mode != WorkoutMode.edit) {
        try {
          await ref
              .read(workoutDayExercisesProvider.notifier)
              .saveSessionExercises(sessionId);
        } catch (e) {
          if (kDebugMode) {
            print('Warning: failed to save session exercises: $e');
          }
          // Continue even if session save fails - the workout log save is more critical
        }
      }

      // Apply mode-specific persistence
      if (mode == WorkoutMode.edit) {
        if (workoutId == null || workoutId.isEmpty) {
          state = const AsyncValue.data(null);
          return FinishResult(
            success: false,
            error: 'workoutId is required for edit',
            needSessionSelection: false,
          );
        }

        // Ensure sessionId exists or request selection
        if (sessionId == null || sessionId.isEmpty) {
          state = const AsyncValue.data(null);
          return FinishResult(success: false, needSessionSelection: true);
        }

        await _service.updateWorkout(
          workoutId: workoutId,
          exercises: exercises,
          startedAt: startedAt,
          endedAt: endedAt,
          sessionId: sessionId,
        );

        final summary = WorkoutMapper.toSummary(
          sessionName: '',
          date: startedAt,
          duration: endedAt.difference(startedAt),
          exercises: exercises,
        );

        // Optionally clear local providers after successful update to avoid
        // leaving stale state when navigating away. This can affect consumers
        // that expect the provider to still hold data — log a warning in debug
        // so maintainers can spot issues.
        if (clearCacheOnSuccess) {
          try {
            if (kDebugMode) {
              print('Info: clearing workout providers after successful update');
            }
            ref.read(workoutDayExercisesProvider.notifier).clearCache();
          } catch (e) {
            if (kDebugMode) {
              print('Warning: failed to clear workoutDayExercisesProvider: $e');
            }
          }

          try {
            ref.read(workoutOriginalDurationProvider.notifier).state = null;
          } catch (e) {
            if (kDebugMode) {
              print(
                'Warning: failed to clear workoutOriginalDurationProvider: $e',
              );
            }
          }
        }

        state = const AsyncValue.data(null);
        return FinishResult(success: true, summary: summary);
      }

      // Create new workout (mode create or manual)
      if (sessionId == null || sessionId.isEmpty) {
        state = const AsyncValue.data(null);
        return FinishResult(
          success: false,
          error: 'sessionId is required to create a workout',
        );
      }

      await _service.saveWorkout(
        exercises: exercises,
        routineId: routineId,
        startedAt: startedAt,
        endedAt: endedAt,
        isManual: selectedDate != null,
        sessionId: sessionId,
      );

      final summary = WorkoutMapper.toSummary(
        sessionName: '',
        date: startedAt,
        duration: endedAt.difference(startedAt),
        exercises: exercises,
      );

      if (clearCacheOnSuccess) {
        try {
          if (kDebugMode) {
            print('Info: clearing workout providers after successful save');
          }
          ref.read(workoutDayExercisesProvider.notifier).clearCache();
        } catch (e) {
          if (kDebugMode) {
            print('Warning: failed to clear workoutDayExercisesProvider: $e');
          }
        }

        try {
          ref.read(workoutOriginalDurationProvider.notifier).state = null;
        } catch (e) {
          if (kDebugMode) {
            print(
              'Warning: failed to clear workoutOriginalDurationProvider: $e',
            );
          }
        }
      }

      state = const AsyncValue.data(null);
      return FinishResult(success: true, summary: summary);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return FinishResult(success: false, error: e.toString());
    } finally {
      try {
        ref.read(workoutTimerProvider.notifier).resetTimer();
      } catch (_) {
        // ignore
      }
    }
  }

  Future<void> discardWorkout() async {
    // Clear exercises cache, reset timer and original duration to avoid stale state
    try {
      ref.read(workoutDayExercisesProvider.notifier).clearCache();
    } catch (_) {}

    try {
      ref.read(workoutTimerProvider.notifier).resetTimer();
    } catch (_) {}

    try {
      ref.read(workoutOriginalDurationProvider.notifier).state = null;
    } catch (_) {}

    state = const AsyncData(null);
  }
}
