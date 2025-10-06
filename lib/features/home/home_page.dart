import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_state.dart';
import 'components/templates/home_template.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      body: HomeTemplate(
        userName: 'Lincoln',
        imageUrl: authState.user?.photoURL,
        onStartWorkout: () => _navigateToWorkout(context),
        onChangeWorkout: () => _changeWorkout(context),
        onQuickCreate: () => _quickCreateWorkout(context),
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
        // TODO: Implementar página de configurações
        break;
    }
  }

  void _navigateToWorkout(BuildContext context) {
    // Implementar navegação
  }

  void _changeWorkout(BuildContext context) {
    // Implementar troca de treino
  }

  void _quickCreateWorkout(BuildContext context) {
    context.push('/workout/quick-create');
  }
}
