import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_router.dart';
import '../auth/auth.dart';
import '../auth/utils/logout_utils.dart';
import '../routines/domain/entities/routine.dart';
import '../workout_day/workout_day.dart';
import 'components/organisms/session_picker_sheet.dart';
import 'components/templates/home_template.dart';
import 'state/home_provider.dart';
import 'state/workout_calendar_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  @override
  void initState() {
    super.initState();
    // Carrega dados iniciais
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Registra no RouteObserver para receber didPopNext
    final modal = ModalRoute.of(context);
    if (modal != null) {
      routeObserver.subscribe(this, modal);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Quando retornamos para a Home (uma rota acima foi fechada), recarrega o estado
    ref.read(homeProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final homeState = ref.watch(homeProvider);
    final userProfile = ref.watch(userProfileProvider);
    final streak = ref.watch(workoutStreakProvider);

    // Determina o nome do usuário com fallbacks apropriados
    final userName = userProfile.when(
      skipLoadingOnRefresh: false,
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
        onRefresh: () => ref.read(homeProvider.notifier).refresh(),
        onAvatarTap: () => _showUserMenu(context, ref),
        metrics: homeState.metrics,
        routineSessions: homeState.todaysRoutine?.sessions ?? [],
        onSelectSession: (session) =>
            ref.read(homeProvider.notifier).selectSession(session),
        streak: streak,
        connectivityBanner: homeState.connectivityBanner,
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
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
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
      case 2: // Histórico
        context.push('/history');
        break;
      case 3: // Config
        context.push('/settings');
        break;
    }
  }

  void _navigateToWorkout(BuildContext context, WidgetRef ref) async {
    final homeState = ref.read(homeProvider);
    final routine = homeState.todaysRoutine;

    if (routine == null) return;

    // If routine has multiple sessions, let user pick which one to do
    Session? selectedSession = homeState.todaysSession;
    if (routine.sessions.length > 1) {
      selectedSession = await SessionPickerSheet.show(
        context,
        sessions: routine.sessions,
        currentSession: homeState.todaysSession,
        onSelectSession: (session) {
          ref.read(homeProvider.notifier).selectSession(session);
        },
      );
      if (selectedSession == null || !context.mounted) return;
    }

    if (selectedSession == null) return;

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutDayScreen.create(
          routineId: routine.id,
          sessionId: selectedSession!.id,
          subtitle: '${selectedSession.name} - ${routine.name}',
        ),
      ),
    );
  }

  void _changeWorkout(BuildContext context) {
    context.push('/routines');
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
