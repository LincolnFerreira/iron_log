import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/routes/app_router.dart';
import 'package:iron_log/core/widgets/page_header_title.dart';
import '../../domain/entities/routine.dart';
import '../bloc/routine_provider.dart';
import '../widgets/reorderable_session_list.dart';
import '../widgets/session_section_title.dart';
import 'package:iron_log/features/workout_history/presentation/components/molecules/workout_history_card.dart';
import '../providers/routine_last_workout_provider.dart';

class RoutineSessionsPage extends ConsumerStatefulWidget {
  final Routine routine;

  const RoutineSessionsPage({super.key, required this.routine});

  @override
  ConsumerState<RoutineSessionsPage> createState() => _SessionEditPageState();
}

class _SessionEditPageState extends ConsumerState<RoutineSessionsPage>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routineNotifierProvider.notifier).loadRoutine(widget.routine.id);
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
    // Subpágina foi fechada — rebusca routine atualizada.
    ref.read(routineNotifierProvider.notifier).loadRoutine(widget.routine.id);
  }

  @override
  Widget build(BuildContext context) {
    final routineState = ref.watch(routineNotifierProvider);
    final routine = routineState.selectedRoutine ?? widget.routine;
    final lastWorkoutAsync = ref.watch(routineLastWorkoutProvider(routine.id));

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: PageHeaderTitle(title: 'Sessões', subtitle: routine.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/routines/${routine.id}/sessions/new', extra: routine);
        },
        tooltip: 'Adicionar Sessão',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableSessionList(
              routine: routine,
              // onSaveCallback: (fn) => _saveSessions = fn,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SessionSectionTitle('Histórico'),
                    TextButton(
                      onPressed: () {
                        // TODO: navegar para tela completa de histórico
                      },
                      child: const Text('Ver tudo'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                lastWorkoutAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (workout) {
                    if (workout == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Nenhum treino registrado ainda'),
                        ),
                      );
                    }
                    return WorkoutHistoryCard(workout: workout);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
