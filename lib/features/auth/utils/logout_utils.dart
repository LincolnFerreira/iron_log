import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_state.dart';

class LogoutUtils {
  static void showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Confirmar Logout'),
            ],
          ),
          content: const Text(
            'Tem certeza que deseja sair da sua conta? Você precisará fazer login novamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _performLogout(context, ref);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _performLogout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Mostrar loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Fazendo logout...'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      // Executar logout através do AuthNotifier
      // Isso atualizará o authStateProvider, fazendo isLoggedIn = false
      await ref.read(authStateProvider.notifier).signOut();

      // Pequeno delay para mostrar o feedback
      await Future.delayed(const Duration(milliseconds: 500));

      // O GoRouter automaticamente redirecionará para /login
      // graças ao listener que monitora mudanças no authStateProvider
      // e à lógica de redirect que verifica isLoggedIn
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Logout realizado com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        // Fallback removido: confiar no redirect do GoRouter via authStateProvider
      }
    } catch (e) {
      // Mostrar erro
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao fazer logout: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: () => _performLogout(context, ref),
            ),
          ),
        );
      }
    }
  }
}
