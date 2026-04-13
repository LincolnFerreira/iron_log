import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/components/exercise_search/exercise_search.dart';
import 'package:iron_log/core/extensions/string_extensions.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import '../molecules/add_exercise_search_results.dart';
import '../molecules/add_exercise_added_list.dart';

class AddExerciseBottomSheet extends ConsumerStatefulWidget {
  final Function(SearchExercise) onExerciseSelected;

  const AddExerciseBottomSheet({super.key, required this.onExerciseSelected});

  @override
  ConsumerState<AddExerciseBottomSheet> createState() =>
      _AddExerciseBottomSheetState();
}

class _AddExerciseBottomSheetState
    extends ConsumerState<AddExerciseBottomSheet> {
  late List<SearchExercise> addedExercises;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    addedExercises = [];
    // Clear previous search state when bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseSearchProvider.notifier).clearSearch();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onExerciseSelected(SearchExercise exercise) {
    // Evita adicionar duplicados
    if (addedExercises.any((e) => e.id == exercise.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${exercise.name.toTitleCase()} já foi adicionado'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Passa para o callback principal
    widget.onExerciseSelected(exercise);

    // Adiciona à lista local de exercícios adicionados
    setState(() {
      addedExercises.add(exercise);
    });

    // Mostra feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercise.name.toTitleCase()} adicionado'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(exerciseSearchProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Adicionar Exercício',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: Navigator.of(context).pop,
                          icon: const Icon(Icons.close),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      addedExercises.isEmpty
                          ? 'Busque e selecione os exercícios que deseja adicionar'
                          : '${addedExercises.length} exercício${addedExercises.length > 1 ? 's' : ''} adicionado${addedExercises.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Inline search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar exercícios...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              ref
                                  .read(exerciseSearchProvider.notifier)
                                  .clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    ref
                        .read(exerciseSearchProvider.notifier)
                        .updateQuery(value);
                    setState(() {}); // update suffix icon
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Results / Added list
              Expanded(
                child: searchState.query.isNotEmpty
                    ? searchState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : searchState.results.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'Nenhum exercício encontrado para "${searchState.query}"',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ),
                            )
                          : AddExerciseSearchResults(
                              results: searchState.results,
                              addedExercises: addedExercises,
                              onExerciseSelected: _onExerciseSelected,
                            )
                    : addedExercises.isNotEmpty
                    ? AddExerciseAddedList(addedExercises: addedExercises)
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Digite para buscar exercícios',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
