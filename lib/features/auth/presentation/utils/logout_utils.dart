import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/components/app_snackbar.dart';
import 'package:iron_log/features/auth/auth_controller.dart';

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
      await ref.read(authStateProvider.notifier).signOut();
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(
          context: context,
          type: AppSnackbarType.error,
          title: 'Erro ao sair',
          message: 'Não foi possível concluir o logout. Tente novamente.',
          actionLabel: 'Tentar',
          onAction: () => _performLogout(context, ref),
        );
      }
    }
  }
}
