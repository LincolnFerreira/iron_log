import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/auth/auth_providers.dart';
import 'package:iron_log/features/auth/domain/entities/user_profile.dart';
import 'package:iron_log/features/auth/presentation/providers/auth_controller.dart';

/// Provider para buscar dados do perfil do usuário autenticado
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authStateProvider).user;
  if (user == null) return null;

  try {
    return await ref.read(authRepositoryProvider).getUserProfile();
  } catch (_) {
    return null;
  }
});

/// Provider para o nome do usuário (extraído do perfil)
final userNameProvider = Provider<String?>((ref) {
  final userProfileAsync = ref.watch(userProfileProvider);

  return userProfileAsync.when(
    data: (profile) => profile?.name,
    loading: () => null,
    error: (_, _) => null,
  );
});

/// Provider para invalidar e recarregar o perfil do usuário
final userProfileRefreshProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(userProfileProvider);
  };
});
