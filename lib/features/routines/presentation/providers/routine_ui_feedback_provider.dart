import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RoutineUiFeedbackKind { success, warning, error }

class RoutineUiFeedbackMessage {
  const RoutineUiFeedbackMessage({
    required this.kind,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionRoutineId,
  });

  final RoutineUiFeedbackKind kind;
  final String title;
  final String message;
  final String? actionLabel;
  final String? actionRoutineId;

  factory RoutineUiFeedbackMessage.success({
    required String title,
    required String message,
    String? actionLabel,
    String? actionRoutineId,
  }) =>
      RoutineUiFeedbackMessage(
        kind: RoutineUiFeedbackKind.success,
        title: title,
        message: message,
        actionLabel: actionLabel,
        actionRoutineId: actionRoutineId,
      );

  factory RoutineUiFeedbackMessage.warning({
    required String title,
    required String message,
  }) =>
      RoutineUiFeedbackMessage(
        kind: RoutineUiFeedbackKind.warning,
        title: title,
        message: message,
      );

  factory RoutineUiFeedbackMessage.error({
    required String title,
    required String message,
  }) =>
      RoutineUiFeedbackMessage(
        kind: RoutineUiFeedbackKind.error,
        title: title,
        message: message,
      );
}

class RoutineUiFeedbackNotifier extends Notifier<RoutineUiFeedbackMessage?> {
  @override
  RoutineUiFeedbackMessage? build() => null;

  void show(RoutineUiFeedbackMessage message) => state = message;

  void clear() => state = null;
}

final routineUiFeedbackProvider =
    NotifierProvider<RoutineUiFeedbackNotifier, RoutineUiFeedbackMessage?>(
  RoutineUiFeedbackNotifier.new,
);

void showRoutineUiFeedback(WidgetRef ref, RoutineUiFeedbackMessage message) {
  ref.read(routineUiFeedbackProvider.notifier).show(message);
}
