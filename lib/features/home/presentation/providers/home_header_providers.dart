import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/auth/auth.dart';

/// Nome exibido no greeting — só rebuilda quando profile/displayName mudam.
final homeGreetingNameProvider = Provider<String>((ref) {
  final displayName = ref.watch(
    authStateProvider.select((s) => s.user?.displayName),
  );
  final profileAsync = ref.watch(userProfileProvider);

  return profileAsync.when(
    skipLoadingOnRefresh: false,
    data: (profile) =>
        profile?.name ?? _firstName(displayName) ?? 'Usuário',
    loading: () => _firstName(displayName) ?? 'Carregando...',
    error: (_, _) => _firstName(displayName) ?? 'Usuário',
  );
});

/// Foto do avatar — select evita rebuilds em mudanças irrelevantes de [AuthState].
final homeUserPhotoUrlProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider.select((s) => s.user?.photoURL));
});

String? _firstName(String? fullName) {
  if (fullName == null || fullName.isEmpty) return null;
  return fullName.split(' ').first;
}
