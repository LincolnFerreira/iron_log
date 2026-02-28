import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/auth_state.dart';
import '../../../auth/utils/logout_utils.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção do Perfil
          _buildProfileSection(context, user),
          const SizedBox(height: 24),

          // Seção de Configurações Gerais
          _buildGeneralSection(context),
          const SizedBox(height: 24),

          // Seção de Conta
          _buildAccountSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perfil',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Usuário',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Email não disponível',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geral',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              context,
              icon: Icons.notifications,
              title: 'Notificações',
              subtitle: 'Gerenciar lembretes de treino',
              onTap: () {
                // TODO: Implementar configurações de notificação
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Em breve!')));
              },
            ),
            const Divider(),
            _buildSettingItem(
              context,
              icon: Icons.dark_mode,
              title: 'Tema',
              subtitle: 'Claro, escuro ou automático',
              onTap: () {
                // TODO: Implementar seleção de tema
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Em breve!')));
              },
            ),
            const Divider(),
            _buildSettingItem(
              context,
              icon: Icons.language,
              title: 'Idioma',
              subtitle: 'Português (Brasil)',
              onTap: () {
                // TODO: Implementar seleção de idioma
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Em breve!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conta',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              context,
              icon: Icons.backup,
              title: 'Backup de Dados',
              subtitle: 'Sincronizar com a nuvem',
              onTap: () {
                // TODO: Implementar backup
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Em breve!')));
              },
            ),
            const Divider(),
            _buildSettingItem(
              context,
              icon: Icons.security,
              title: 'Privacidade',
              subtitle: 'Controle seus dados',
              onTap: () {
                // TODO: Implementar configurações de privacidade
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Em breve!')));
              },
            ),
            const Divider(),
            _buildSettingItem(
              context,
              icon: Icons.logout,
              title: 'Sair',
              subtitle: 'Fazer logout da conta',
              onTap: () => LogoutUtils.showLogoutDialog(context, ref),
              iconColor: Theme.of(context).colorScheme.error,
              textColor: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: textColor),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
