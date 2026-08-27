// features/auth/auth_state.dart
import 'package:firebase_auth/firebase_auth.dart';

enum AuthFeedbackKind { success, warning, error }

class AuthFeedback {
  const AuthFeedback({
    required this.kind,
    required this.title,
    required this.message,
  });

  final AuthFeedbackKind kind;
  final String title;
  final String message;

  factory AuthFeedback.success({required String title, required String message}) =>
      AuthFeedback(kind: AuthFeedbackKind.success, title: title, message: message);

  factory AuthFeedback.warning({required String title, required String message}) =>
      AuthFeedback(kind: AuthFeedbackKind.warning, title: title, message: message);

  factory AuthFeedback.error({required String title, required String message}) =>
      AuthFeedback(kind: AuthFeedbackKind.error, title: title, message: message);
}

class AuthState {
  final User? user;
  final bool onboardingCompleted;
  final bool isLoading;
  final bool isSigningIn;
  final AuthFeedback? feedback;

  const AuthState({
    this.user,
    this.onboardingCompleted = false,
    this.isLoading = true,
    this.isSigningIn = false,
    this.feedback,
  });

  static const _noUserChange = Object();
  static const _noFeedbackChange = Object();

  AuthState copyWith({
    Object? user = _noUserChange,
    bool? onboardingCompleted,
    bool? isLoading,
    bool? isSigningIn,
    Object? feedback = _noFeedbackChange,
  }) {
    return AuthState(
      user: identical(user, _noUserChange) ? this.user : user as User?,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isLoading: isLoading ?? this.isLoading,
      isSigningIn: isSigningIn ?? this.isSigningIn,
      feedback: identical(feedback, _noFeedbackChange)
          ? this.feedback
          : feedback as AuthFeedback?,
    );
  }

  bool get isLoggedIn => user != null;
}
