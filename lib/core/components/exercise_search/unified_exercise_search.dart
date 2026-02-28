import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/core/api/endpoints.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';

/// Provider para gerenciar a busca unificada de exercícios
final unifiedExerciseSearchQueryProvider = StateProvider<String>((ref) => '');
final unifiedExerciseSearchResultsProvider =
    StateProvider<List<SearchExercise>>((ref) => []);
final unifiedExerciseSearchLoadingProvider = StateProvider<bool>(
  (ref) => false,
);

/// Componente unificado de busca de exercícios
/// Substitui as implementações duplicadas espalhadas pelo projeto
class UnifiedExerciseSearch extends ConsumerStatefulWidget {
  final String hintText;
  final Function(SearchExercise)? onExerciseSelected;
  final bool useSearchAnchor;
  final Widget Function(List<SearchExercise>, String)? resultsBuilder;

  const UnifiedExerciseSearch({
    super.key,
    this.hintText = 'Buscar exercícios...',
    this.onExerciseSelected,
    this.useSearchAnchor = false,
    this.resultsBuilder,
  });

  @override
  ConsumerState<UnifiedExerciseSearch> createState() =>
      _UnifiedExerciseSearchState();
}

class _UnifiedExerciseSearchState extends ConsumerState<UnifiedExerciseSearch> {
  Timer? _debounceTimer;
  final TextEditingController _controller = TextEditingController();
  final SearchController _searchController = SearchController();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useSearchAnchor) {
      return _buildSearchAnchor();
    } else {
      return _buildTextField();
    }
  }

  Widget _buildTextField() {
    final searchQuery = ref.watch(unifiedExerciseSearchQueryProvider);
    final isLoading = ref.watch(unifiedExerciseSearchLoadingProvider);

    return TextField(
      controller: _controller,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildSearchAnchor() {
    return SearchAnchor(
      isFullScreen: true,
      searchController: _searchController,
      builder: (BuildContext context, SearchController controller) {
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: () => controller.openView(),
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        );
      },
      suggestionsBuilder:
          (BuildContext context, SearchController controller) async {
            final query = controller.text;
            ref.read(unifiedExerciseSearchQueryProvider.notifier).state = query;

            if (query.isNotEmpty) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(
                const Duration(milliseconds: 300),
                () async {
                  await _performSearch(query);
                },
              );
            }

            final results = ref.read(unifiedExerciseSearchResultsProvider);
            return _buildSuggestions(results, controller, query);
          },
    );
  }

  void _onSearchChanged(String value) {
    ref.read(unifiedExerciseSearchQueryProvider.notifier).state = value;
    _controller.text = value;

    _debounceTimer?.cancel();
    if (value.isEmpty) {
      ref.read(unifiedExerciseSearchResultsProvider.notifier).state = [];
      ref.read(unifiedExerciseSearchLoadingProvider.notifier).state = false;
      return;
    }

    ref.read(unifiedExerciseSearchLoadingProvider.notifier).state = true;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _performSearch(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(unifiedExerciseSearchQueryProvider.notifier).state = '';
    ref.read(unifiedExerciseSearchResultsProvider.notifier).state = [];
    ref.read(unifiedExerciseSearchLoadingProvider.notifier).state = false;
    _debounceTimer?.cancel();
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      ref.read(unifiedExerciseSearchResultsProvider.notifier).state = [];
      ref.read(unifiedExerciseSearchLoadingProvider.notifier).state = false;
      return;
    }

    try {
      ref.read(unifiedExerciseSearchLoadingProvider.notifier).state = true;

      final auth = AuthService();
      auth.initialize();
      final response = await auth.authenticatedRequest(
        method: 'GET',
        path: ApiEndpoints.exerciseSearch,
        queryParameters: {'q': query, 'limit': 30},
      );

      final results = (response.data as List).cast<Map<String, dynamic>>();
      final searchExercises = results
          .map((exercise) => SearchExercise.fromJson(exercise))
          .toList();

      ref.read(unifiedExerciseSearchResultsProvider.notifier).state =
          searchExercises;
    } catch (e) {
      ref.read(unifiedExerciseSearchResultsProvider.notifier).state = [];
    } finally {
      ref.read(unifiedExerciseSearchLoadingProvider.notifier).state = false;
    }
  }

  List<Widget> _buildSuggestions(
    List<SearchExercise> results,
    SearchController controller,
    String query,
  ) {
    if (query.isEmpty) {
      return [_buildEmptyState()];
    }

    if (results.isEmpty) {
      return [_buildNoResultsState(controller, query)];
    }

    return results.map((exercise) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(exercise.category ?? ''),
          child: Text(
            (exercise.category?.isNotEmpty == true)
                ? exercise.category![0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          exercise.muscles.isNotEmpty
              ? exercise.muscles.join(', ')
              : exercise.primaryMuscle ?? 'Não especificado',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        onTap: () {
          controller.closeView(exercise.name);
          widget.onExerciseSelected?.call(exercise);
        },
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'Encontre seu exercício',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Digite o nome do exercício que você procura',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ex: supino, agachamento, remada...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(SearchController controller, String query) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'Nenhum exercício encontrado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tente usar palavras diferentes ou verifique a ortografia',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await _createExercise(controller, query);
            },
            icon: const Icon(Icons.add),
            label: Text("Criar exercício '$query'"),
          ),
        ],
      ),
    );
  }

  Future<void> _createExercise(SearchController controller, String name) async {
    if (name.trim().isEmpty) return;

    try {
      ref.read(unifiedExerciseSearchLoadingProvider.notifier).state = true;

      final auth = AuthService();
      auth.initialize();

      final response = await auth.authenticatedRequest(
        method: 'GET',
        path: ApiEndpoints.exerciseFindOrCreate,
        queryParameters: {'name': name.trim()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final created = SearchExercise.fromJson(response.data as Map<String, dynamic>);

        // Close the search view with the created name and notify parent
        controller.closeView(created.name);
        widget.onExerciseSelected?.call(created);

        // Optionally add to results cache
        final current = ref.read(unifiedExerciseSearchResultsProvider);
        ref.read(unifiedExerciseSearchResultsProvider.notifier).state = [created, ...current];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar exercício'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar exercício: $e'), backgroundColor: Colors.red),
      );
    } finally {
      ref.read(unifiedExerciseSearchLoadingProvider.notifier).state = false;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'multi':
        return Colors.blue;
      case 'iso':
        return Colors.green;
      case 'cardio':
        return Colors.red;
      case 'funcional':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
