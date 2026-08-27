import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeUiFeedbackKind { success, warning, error }

class HomeUiFeedbackMessage {
  const HomeUiFeedbackMessage({
    required this.kind,
    required this.title,
    required this.message,
  });

  final HomeUiFeedbackKind kind;
  final String title;
  final String message;

  factory HomeUiFeedbackMessage.success({
    required String title,
    required String message,
  }) =>
      HomeUiFeedbackMessage(
        kind: HomeUiFeedbackKind.success,
        title: title,
        message: message,
      );

  factory HomeUiFeedbackMessage.warning({
    required String title,
    required String message,
  }) =>
      HomeUiFeedbackMessage(
        kind: HomeUiFeedbackKind.warning,
        title: title,
        message: message,
      );

  factory HomeUiFeedbackMessage.error({
    required String title,
    required String message,
  }) =>
      HomeUiFeedbackMessage(
        kind: HomeUiFeedbackKind.error,
        title: title,
        message: message,
      );
}

class HomeUiFeedbackNotifier extends Notifier<HomeUiFeedbackMessage?> {
  @override
  HomeUiFeedbackMessage? build() => null;

  void show(HomeUiFeedbackMessage message) => state = message;

  void clear() => state = null;
}

final homeUiFeedbackProvider =
    NotifierProvider<HomeUiFeedbackNotifier, HomeUiFeedbackMessage?>(
  HomeUiFeedbackNotifier.new,
);

void showHomeUiFeedback(WidgetRef ref, HomeUiFeedbackMessage message) {
  ref.read(homeUiFeedbackProvider.notifier).show(message);
}
