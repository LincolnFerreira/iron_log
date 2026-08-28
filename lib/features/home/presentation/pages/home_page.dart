import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/components/app_snackbar.dart';
import 'package:iron_log/core/routes/app_router.dart';
import 'package:iron_log/core/routes/workout_route_locations.dart';
import 'package:iron_log/features/auth/auth.dart';
import 'package:iron_log/features/auth/presentation/utils/logout_utils.dart';
import 'package:iron_log/features/home/presentation/components/organisms/session_picker_sheet.dart';
import 'package:iron_log/features/home/presentation/components/templates/home_template.dart';
import 'package:iron_log/features/home/presentation/providers/home_provider.dart';
import 'package:iron_log/features/home/presentation/providers/home_ui_feedback_provider.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/workout_day/presentation/providers/workout_draft_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    ref.read(homeProvider.notifier).refresh();
    ref.invalidate(activeWorkoutDraftProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeUiFeedbackProvider, (previous, next) {
      if (next == null || !mounted) return;

      switch (next.kind) {
        case HomeUiFeedbackKind.success:
          AppSnackbar.success(
            context: context,
            title: next.title,
            message: next.message,
          );
        case HomeUiFeedbackKind.warning:
          AppSnackbar.warning(
            context: context,
            title: next.title,
            message: next.message,
          );
        case HomeUiFeedbackKind.error:
          AppSnackbar.error(
            context: context,
            title: next.title,
            message: next.message,
          );
      }
      ref.read(homeUiFeedbackProvider.notifier).clear();
    });

    // Estado reativo vive em Consumers dentro de [HomeTemplate] (T073).
    return Scaffold(
      body: HomeTemplate(
        onStartWorkout: () => _navigateToWorkout(context, ref),
        onContinueWorkout: () {
          final draftId =
              ref.read(activeWorkoutDraftProvider).valueOrNull?.id;
          if (draftId != null) {
            _navigateToResume(context, draftId);
          }
        },
        onChangeWorkout: () => _changeWorkout(context),
        onQuickCreate: () => _quickCreateWorkout(context),
        onRetryWorkout: () => _retryWorkout(ref),
        onRefresh: () => ref.read(homeProvider.notifier).refresh(),
        onAvatarTap: () => _showUserMenu(context, ref),
        onSelectSession: (session) =>
            ref.read(homeProvider.notifier).selectSession(session),
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
      ).colorScheme.onSurface.withValues(alpha: 0.6),
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
      case 0:
        break;
      case 1:
        context.push('/routines');
        break;
      case 2:
        context.push('/history');
        break;
      case 3:
        context.push('/settings');
        break;
    }
  }

  void _navigateToWorkout(BuildContext context, WidgetRef ref) async {
    final activeDraft = ref.read(activeWorkoutDraftProvider).valueOrNull;
    if (activeDraft != null && context.mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Treino em andamento'),
          content: const Text(
            'Você já tem um treino não finalizado. Deseja continuar de onde parou?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (proceed == true && context.mounted) {
        _navigateToResume(context, activeDraft.id);
      }
      return;
    }

    final homeState = ref.read(homeProvider);
    final routine = homeState.todaysRoutine;

    if (routine == null) return;

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
    context.push(
      WorkoutRouteLocations.executionPath(
        routineId: routine.id,
        sessionId: selectedSession.id,
        subtitle: '${selectedSession.name} - ${routine.name}',
      ),
    );
  }

  void _navigateToResume(BuildContext context, String draftId) {
    context.push(WorkoutRouteLocations.resume(draftId));
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
        return Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(
              authStateProvider.select((s) => s.user),
            );

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Text(
                                user?.displayName
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
      },
    );
  }
}
