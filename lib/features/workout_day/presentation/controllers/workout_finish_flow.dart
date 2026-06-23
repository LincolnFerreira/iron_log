import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/components/app_snackbar.dart';
import 'package:iron_log/core/routes/workout_route_locations.dart';
import 'package:iron_log/features/home/presentation/components/organisms/session_picker_sheet.dart';
import 'package:iron_log/features/home/presentation/providers/home_provider.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';
import 'package:iron_log/features/workout_day/domain/workout_mode.dart';
import 'package:iron_log/features/workout_day/presentation/controllers/workout_controller.dart';
import 'package:iron_log/features/workout_day/presentation/workout_test_keys.dart';
import 'package:iron_log/features/workout_day/presentation/providers/workout_timer_provider.dart';

/// UI orchestration for finishing a workout (duration picker, session picker, navigation).
class WorkoutFinishFlow {
  WorkoutFinishFlow._();

  static WorkoutMode resolveMode({
    String? workoutId,
    DateTime? manualDate,
  }) {
    if (workoutId != null && workoutId.isNotEmpty) {
      return WorkoutMode.edit;
    }
    if (manualDate != null) {
      return WorkoutMode.manual;
    }
    return WorkoutMode.create;
  }

  static Future<Duration?> pickDuration(BuildContext context) async {
    final hoursCtrl = TextEditingController(text: '1');
    final minutesCtrl = TextEditingController(text: '0');

    try {
      return await showDialog<Duration>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Duração do treino'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hoursCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Horas',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: minutesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minutos',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: WorkoutTestKeys.durationConfirm,
              onPressed: () {
                final h = int.tryParse(hoursCtrl.text) ?? 0;
                final m = int.tryParse(minutesCtrl.text) ?? 0;
                Navigator.pop(ctx, Duration(hours: h, minutes: m));
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    } finally {
      hoursCtrl.dispose();
      minutesCtrl.dispose();
    }
  }

  /// Runs finish + retries (duration / session) and handles navigation feedback.
  static Future<void> run({
    required BuildContext context,
    required WidgetRef ref,
    required WorkoutMode mode,
    required List<WorkoutExercise> exercises,
    String? routineId,
    String? sessionId,
    String? workoutId,
    DateTime? selectedDate,
    required VoidCallback onWorkoutNotStarted,
    required bool Function() isMounted,
  }) async {
    final timerStartTime = ref.read(workoutTimerProvider);
    final controller = ref.read(workoutControllerProvider.notifier);

    var result = await controller.finishWorkout(
      mode: mode,
      exercises: exercises,
      routineId: routineId,
      sessionId: sessionId,
      workoutId: workoutId,
      selectedDate: selectedDate,
      timerStartTime: timerStartTime,
    );

    if (result.needDuration) {
      final picked = await pickDuration(context);
      if (!isMounted()) return;
      if (picked == null) {
        onWorkoutNotStarted();
        return;
      }
      result = await controller.finishWorkout(
        mode: mode,
        exercises: exercises,
        routineId: routineId,
        sessionId: sessionId,
        workoutId: workoutId,
        selectedDate: selectedDate,
        timerStartTime: timerStartTime,
        manualDuration: picked,
      );
    }

    if (result.needSessionSelection) {
      final homeState = ref.read(homeProvider);
      final routine = homeState.todaysRoutine;
      if (routine != null && routine.sessions.isNotEmpty) {
        if (!isMounted()) return;
        final selectedSession = await SessionPickerSheet.show(
          context,
          sessions: routine.sessions,
          onSelectSession: (_) {},
        );
        if (selectedSession == null || !isMounted()) {
          onWorkoutNotStarted();
          return;
        }
        result = await controller.finishWorkout(
          mode: mode,
          exercises: exercises,
          routineId: routineId,
          sessionId: selectedSession.id,
          workoutId: workoutId,
          selectedDate: selectedDate,
          timerStartTime: timerStartTime,
        );
      } else {
        if (isMounted()) {
          onWorkoutNotStarted();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma sessão disponível para selecionar.'),
            ),
          );
        }
        return;
      }
    }

    if (result.success && result.summary != null) {
      if (mode == WorkoutMode.edit) {
        if (!isMounted()) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino atualizado com sucesso!')),
        );
        Navigator.of(context).pop();
      } else {
        if (!isMounted()) return;
        await context.push(
          WorkoutRouteLocations.summaryPath,
          extra: result.summary,
        );
      }
      return;
    }

    if (isMounted()) {
      onWorkoutNotStarted();
      if (result.savedLocally) {
        AppSnackbar.warning(
          context: context,
          title: 'Treino salvo no dispositivo',
          message:
              'O envio falhou, mas seus dados estão seguros. '
              'Reenvie depois em Configurações → Treinos pendentes.',
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao finalizar treino: ${result.error ?? 'unknown'}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
