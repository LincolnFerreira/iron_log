import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<void> upsertUser({
    required String firebaseId,
    required String email,
    String? name,
  });

  Future<UserProfile?> getUserProfile();
}
