import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/routine.dart';
import 'selected_exercises_section.dart';
import 'exercise_search_field.dart';
import 'exercise_search_results.dart';

class SessionDetailContent extends ConsumerStatefulWidget {
  final Routine routine;
  final Session session;

  const SessionDetailContent({
    super.key,
    required this.routine,
    required this.session,
  });

  @override
  ConsumerState<SessionDetailContent> createState() =>
      _SessionDetailContentState();
}

class _SessionDetailContentState extends ConsumerState<SessionDetailContent> {
  late SearchController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedExerciseIds = ref.watch(selectedExerciseIdsProvider);
    final hasSelectedExercises = selectedExerciseIds.isNotEmpty;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com botão de busca
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configurar ${widget.session.name}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecione os exercícios para esta sessão',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                SearchAnchor(
                  searchController: _searchController,
                  isFullScreen: true,
                  builder: (BuildContext context, SearchController controller) {
                    return FilledButton.icon(
                      onPressed: () {
                        controller.openView();
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                    );
                  },
                  suggestionsBuilder:
                      (BuildContext context, SearchController controller) {
                        return [];
                      },
                  viewBuilder: (Iterable<Widget> suggestions) {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Buscar Exercícios'),
                        elevation: 0,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      ),
                      body: Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: const Column(
                          children: [
                            // Campo de busca
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: ExerciseSearchField(),
                            ),

                            // Resultados da busca
                            Expanded(child: ExerciseSearchResults()),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Exercícios selecionados (ocupa toda a tela restante)
          Expanded(child: SelectedExercisesSection(session: widget.session)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: hasSelectedExercises ? _onConcluir : null,
        icon: const Icon(Icons.check),
        label: const Text('Concluir'),
        backgroundColor: hasSelectedExercises
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        foregroundColor: hasSelectedExercises
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
      ),
    );
  }

  void _onConcluir() {
    // TODO: Salvar configuração da sessão no backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sessão configurada com sucesso!'),
        duration: Duration(seconds: 2),
      ),
    );

    // Voltar para a tela anterior
    context.pop();
  }
}
