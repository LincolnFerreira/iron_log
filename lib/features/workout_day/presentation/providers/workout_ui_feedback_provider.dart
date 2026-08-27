import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WorkoutUiFeedbackKind { success, warning, error, info }

class WorkoutUiFeedbackMessage {
  const WorkoutUiFeedbackMessage({
    required this.kind,
    required this.title,
    required this.message,
  });

  final WorkoutUiFeedbackKind kind;
  final String title;
  final String message;

  factory WorkoutUiFeedbackMessage.success({
    required String title,
    required String message,
  }) =>
      WorkoutUiFeedbackMessage(
        kind: WorkoutUiFeedbackKind.success,
        title: title,
        message: message,
      );

  factory WorkoutUiFeedbackMessage.warning({
    required String title,
    required String message,
  }) =>
      WorkoutUiFeedbackMessage(
        kind: WorkoutUiFeedbackKind.warning,
        title: title,
        message: message,
      );

  factory WorkoutUiFeedbackMessage.error({
    required String title,
    required String message,
  }) =>
      WorkoutUiFeedbackMessage(
        kind: WorkoutUiFeedbackKind.error,
        title: title,
        message: message,
      );
}

class WorkoutUiFeedbackNotifier extends Notifier<WorkoutUiFeedbackMessage?> {
  @override
  WorkoutUiFeedbackMessage? build() => null;

  void show(WorkoutUiFeedbackMessage message) => state = message;

  void clear() => state = null;
}

final workoutUiFeedbackProvider =
    NotifierProvider<WorkoutUiFeedbackNotifier, WorkoutUiFeedbackMessage?>(
  WorkoutUiFeedbackNotifier.new,
);

void showWorkoutUiFeedback(WidgetRef ref, WorkoutUiFeedbackMessage message) {
  ref.read(workoutUiFeedbackProvider.notifier).show(message);
}
