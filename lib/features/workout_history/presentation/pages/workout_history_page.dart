import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/home/state/home_provider.dart';
import 'package:iron_log/features/workout_day/presentation/components/molecules/history_item_card.dart';
import 'package:iron_log/features/workout_day/presentation/pages/workout_day_screen.dart';
import 'package:iron_log/features/workout_history/presentation/providers/workout_history_provider.dart';
import 'package:iron_log/core/routes/app_router.dart';

class WorkoutHistoryPage extends ConsumerStatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  ConsumerState<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends ConsumerState<WorkoutHistoryPage>
    with WidgetsBindingObserver, RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(workoutHistoryProvider);
    });
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Voltamos para esta página (subpágina foi fechada) — recarrega.
    ref.invalidate(workoutHistoryProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(workoutHistoryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Treinos'),
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Não foi possível carregar o histórico.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(workoutHistoryProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (workouts) => workouts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum treino registrado',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use o botão abaixo para registrar um treino passado.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(workoutHistoryProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) => HistoryItemCard(
                    workoutHistory: workouts[index],
                    animated: false,
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _registerPastWorkout(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar treino passado'),
      ),
    );
  }

  Future<void> _registerPastWorkout(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
      helpText: 'Quando foi este treino?',
    );

    if (picked == null || !context.mounted) return;

    final homeState = ref.read(homeProvider);
    final routineId = homeState.todaysRoutine?.id;
    final sessionId = homeState.todaysSession?.id;
    final subtitle =
        homeState.todaysSession != null && homeState.todaysRoutine != null
        ? '${homeState.todaysSession!.name} - ${homeState.todaysRoutine!.name}'
        : '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutDayScreen(
          routineId: routineId,
          sessionId: sessionId,
          subtitle: subtitle,
          manualDate: picked,
        ),
      ),
    );
  }
}
