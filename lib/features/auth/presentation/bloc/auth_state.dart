part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthState {
  final AuthStatus status;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.error,
  });
}
