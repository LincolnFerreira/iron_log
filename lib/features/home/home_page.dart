import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth.dart';
import '../auth/utils/logout_utils.dart';
import '../workout_day/workout_day.dart';
import 'components/templates/home_template.dart';
import 'state/home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final homeState = ref.watch(homeProvider);
    final userProfile = ref.watch(userProfileProvider);

    // Determina o nome do usuário com fallbacks apropriados
    final userName = userProfile.when(
      data: (profile) =>
          profile?.name ??
          _getFirstName(authState.user?.displayName) ??
          'Usuário',
      loading: () =>
          _getFirstName(authState.user?.displayName) ?? 'Carregando...',
      error: (_, __) => _getFirstName(authState.user?.displayName) ?? 'Usuário',
    );

    return Scaffold(
      body: HomeTemplate(
        userName: userName,
        imageUrl: authState.user?.photoURL,
        todaysRoutine: homeState.todaysRoutine,
        todaysSession: homeState.todaysSession,
        isLoadingWorkout: homeState.isLoading,
        error: homeState.error,
        onStartWorkout: () => _navigateToWorkout(context, ref),
        onChangeWorkout: () => _changeWorkout(context),
        onQuickCreate: () => _quickCreateWorkout(context),
        onRetryWorkout: () => _retryWorkout(ref),
        onAvatarTap: () => _showUserMenu(context, ref),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(
        context,
      ).colorScheme.onSurface.withOpacity(0.6),
      onTap: (index) => _onBottomNavTap(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Treinos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          label: 'Progresso',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
      ],
    );
  }

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0: // Home
        // Já estamos na home
        break;
      case 1: // Treinos
        context.push('/routines');
        break;
      case 2: // Progresso
        // TODO: Implementar página de progresso
        break;
      case 3: // Config
        context.push('/settings');
        break;
    }
  }

  void _navigateToWorkout(BuildContext context, WidgetRef ref) {
    final homeState = ref.read(homeProvider);
    if (homeState.todaysRoutine != null && homeState.todaysSession != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WorkoutDayScreen(
            routineId: homeState.todaysRoutine!.id,
            sessionId: homeState.todaysSession!.id,
            subtitle:
                '${homeState.todaysSession!.name} - ${homeState.todaysRoutine!.name}',
          ),
        ),
      );
    }
  }

  void _changeWorkout(BuildContext context) {
    // Implementar troca de treino
  }

  void _quickCreateWorkout(BuildContext context) {
    context.push('/workout/quick-create');
  }

  void _retryWorkout(WidgetRef ref) {
    ref.read(homeProvider.notifier).refresh();
  }

  void _showUserMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final authState = ref.watch(authStateProvider);
        final user = authState.user;

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // User info
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
                        Text(
                          user?.email ?? 'Email não disponível',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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

              const SizedBox(height: 24),

              // Menu options
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Sair',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  LogoutUtils.showLogoutDialog(context, ref);
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Extrai apenas o primeiro nome de um nome completo
  String? _getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return null;
    return fullName.split(' ').first;
  }
}
