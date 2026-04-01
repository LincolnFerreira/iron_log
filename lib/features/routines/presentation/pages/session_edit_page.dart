import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/routes/app_router.dart';
import 'package:iron_log/core/widgets/page_header_title.dart';
import '../../domain/entities/routine.dart';
import '../bloc/routine_provider.dart';
import '../widgets/reorderable_session_list.dart';
import '../widgets/session_section_title.dart';
import 'package:iron_log/features/workout_day/presentation/organisms/exercise_card.dart';
import '../providers/routine_history_provider.dart';

class SessionEditPage extends ConsumerStatefulWidget {
  final Routine routine;

  const SessionEditPage({super.key, required this.routine});

  @override
  ConsumerState<SessionEditPage> createState() => _SessionEditPageState();
}

class _SessionEditPageState extends ConsumerState<SessionEditPage>
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
    final historyAsync = ref.watch(routineHistoryProvider(routine.id));

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: PageHeaderTitle(title: 'Rotina', subtitle: routine.name),
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
          Expanded(child: ReorderableSessionList(routine: routine)),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final height = (constraints.maxHeight * 0.28).clamp(
                      120.0,
                      220.0,
                    );
                    return SizedBox(
                      height: height,
                      child: historyAsync.when(
                        data: (exercises) {
                          if (exercises.isEmpty) {
                            return const Center(
                              child: Text('Nenhum histórico disponível'),
                            );
                          }
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: exercises.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final ex = exercises[index];
                              return SizedBox(
                                width: 300,
                                child: ExerciseCard(exercise: ex),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, st) => const Center(
                          child: Text('Erro ao carregar histórico'),
                        ),
                      ),
                    );
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
