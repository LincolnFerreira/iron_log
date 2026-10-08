import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/auth/domain/entities/user_profile.dart';

/// Acesso remoto de auth (upsert + perfil).
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._http);

  final HttpService _http;

  /// Garante que o usuário existe no backend usando o token Firebase.
  /// O guard em `/auth/me` cria o registro na primeira vez e reutiliza nas próximas.
  Future<void> upsertUser({
    required String firebaseId,
    required String email,
    String? name,
  }) async {
    await _http.get(ApiEndpoints.me);
  }

  /// GET `/auth/me` — retorna null se a resposta não trouxer `user`.
  Future<UserProfile?> fetchUserProfile() async {
    final response = await _http.get(ApiEndpoints.me);
    final userData = response.data as Map<String, dynamic>?;
    if (userData == null) return null;
    final userObject = userData['user'] as Map<String, dynamic>?;
    if (userObject == null) return null;
    return UserProfile.fromJson(userObject);
  }
}
