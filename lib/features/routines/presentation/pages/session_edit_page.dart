import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/routine.dart';
import '../widgets/reorderable_session_list.dart';
import '../widgets/session_section_title.dart';
import 'package:iron_log/features/workout_day/presentation/organisms/exercise_card.dart';
import '../providers/routine_history_provider.dart';

class SessionEditPage extends ConsumerWidget {
  final Routine routine;

  const SessionEditPage({super.key, required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(routineHistoryProvider(routine.id));

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text('Rotina ${routine.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Adicionar nova sessão (leva para criação)
          context.push('/routines/${routine.id}/sessions/new', extra: routine);
        },
        tooltip: 'Adicionar Sessão',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Lista de sessões/edição principal (expande)
          Expanded(child: ReorderableSessionList(routine: routine)),

          // Histórico resumido dos últimos treinos
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
                        error: (e, st) =>
                            Center(child: Text('Erro ao carregar histórico')),
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
