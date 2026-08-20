import 'package:iron_log/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:iron_log/features/auth/domain/entities/user_profile.dart';
import 'package:iron_log/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<void> upsertUser({
    required String firebaseId,
    required String email,
    String? name,
  }) =>
      _remote.upsertUser(
        firebaseId: firebaseId,
        email: email,
        name: name,
      );

  @override
  Future<UserProfile?> getUserProfile() => _remote.fetchUserProfile();
}
