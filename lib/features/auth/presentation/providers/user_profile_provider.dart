import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/auth_service.dart';
import '../../domain/entities/user_profile.dart';

/// Provider para buscar dados do perfil do usuário autenticado
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    final auth = AuthService();
    auth.initialize();

    // Usa o método getUserProfile que já trata a resposta corretamente
    return await auth.getUserProfile();
  } catch (error) {
    // Em caso de erro, retorna null (usuário não logado ou erro de rede)
    return null;
  }
});

/// Provider para o nome do usuário (extraído do perfil)
final userNameProvider = Provider<String?>((ref) {
  final userProfileAsync = ref.watch(userProfileProvider);

  return userProfileAsync.when(
    data: (profile) => profile?.name,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider para invalidar e recarregar o perfil do usuário
final userProfileRefreshProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(userProfileProvider);
  };
});
