// features/auth/auth_state.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  final User? user;
  final bool onboardingCompleted;
  final bool isLoading;

  const AuthState({
    this.user,
    this.onboardingCompleted = false,
    this.isLoading = true,
  });

  static const _noUserChange = Object();

  AuthState copyWith({
    Object? user = _noUserChange,
    bool? onboardingCompleted,
    bool? isLoading,
  }) {
    return AuthState(
      user: identical(user, _noUserChange) ? this.user : user as User?,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isLoggedIn => user != null;
}
