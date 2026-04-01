import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/core/api/endpoints.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';

// ============================================================================
// STATE CLASS
// ============================================================================

/// Estado encapsulado da busca de exercícios
class ExerciseSearchState {
  final String query;
  final List<SearchExercise> results;
  final bool isLoading;

  ExerciseSearchState({
    required this.query,
    required this.results,
    required this.isLoading,
  });

  /// Cria uma cópia com parâmetros modificados
  ExerciseSearchState copyWith({
    String? query,
    List<SearchExercise>? results,
    bool? isLoading,
  }) {
    return ExerciseSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Estado inicial
  factory ExerciseSearchState.initial() {
    return ExerciseSearchState(query: '', results: [], isLoading: false);
  }
}

// ============================================================================
// STATE NOTIFIER
// ============================================================================

/// Notifier que gerencia a busca de exercícios com debounce integrado
class ExerciseSearchNotifier extends StateNotifier<ExerciseSearchState> {
  Timer? _debounceTimer;
  int _searchCounter = 0;

  ExerciseSearchNotifier() : super(ExerciseSearchState.initial());

  /// Atualiza a query e faz debounce da busca
  void updateQuery(String query) {
    // Atualiza a query imediatamente
    state = state.copyWith(query: query);

    // Cancela timer anterior
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      // Limpa resultados se a query estiver vazia
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    // Inicia loading e debounce
    state = state.copyWith(isLoading: true);
    final currentCounter = ++_searchCounter;

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query, currentCounter);
    });
  }

  /// Realiza a busca de exercícios (ignora respostas antigas usando token)
  Future<void> _performSearch(String query, int token) async {
    if (query.length < 2) {
      if (token == _searchCounter) {
        state = state.copyWith(results: [], isLoading: false);
      }
      return;
    }

    try {
      final auth = AuthService();
      auth.initialize();
      final response = await auth.authenticatedRequest(
        method: 'GET',
        path: ApiEndpoints.exerciseSearch,
        queryParameters: {'q': query, 'limit': 30},
      );

      // Ignora respostas que não pertençam à última busca
      if (token != _searchCounter) return;

      final results = (response.data as List).cast<Map<String, dynamic>>();
      final searchExercises = results
          .map((exercise) => SearchExercise.fromJson(exercise))
          .toList();

      // Atualiza resultados e termina loading
      state = state.copyWith(results: searchExercises, isLoading: false);
    } catch (e) {
      if (token == _searchCounter) {
        state = state.copyWith(results: [], isLoading: false);
      }
    }
  }

  /// Cria um novo exercício e o retorna
  Future<SearchExercise?> createExercise(String name) async {
    if (name.trim().isEmpty) return null;

    try {
      final auth = AuthService();
      auth.initialize();

      final response = await auth.authenticatedRequest(
        method: 'GET',
        path: ApiEndpoints.exerciseFindOrCreate,
        queryParameters: {'name': name.trim()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final created = SearchExercise.fromJson(
          response.data as Map<String, dynamic>,
        );

        // Adiciona ao início da lista
        state = state.copyWith(results: [created, ...state.results]);

        return created;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Limpa a busca
  void clearSearch() {
    _debounceTimer?.cancel();
    state = ExerciseSearchState.initial();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

/// Provider para gerenciar a busca unificada de exercícios
final exerciseSearchProvider =
    StateNotifierProvider<ExerciseSearchNotifier, ExerciseSearchState>((ref) {
      return ExerciseSearchNotifier();
    });

// Providers auxiliares para acesso fácil aos estados individuais
final exerciseSearchQueryProvider = Provider<String>((ref) {
  return ref.watch(exerciseSearchProvider).query;
});

final exerciseSearchResultsProvider = Provider<List<SearchExercise>>((ref) {
  return ref.watch(exerciseSearchProvider).results;
});

final exerciseSearchLoadingProvider = Provider<bool>((ref) {
  return ref.watch(exerciseSearchProvider).isLoading;
});

// ============================================================================
// COMPONENTE
// ============================================================================

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
  final TextEditingController _controller = TextEditingController();
  final SearchController _searchController = SearchController();

  @override
  void dispose() {
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
    final searchState = ref.watch(exerciseSearchProvider);

    return TextField(
      controller: _controller,
      onChanged: (value) {
        ref.read(exerciseSearchProvider.notifier).updateQuery(value);
      },
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: searchState.isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.search),
        suffixIcon: searchState.query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  ref.read(exerciseSearchProvider.notifier).clearSearch();
                },
              )
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
    final searchState = ref.watch(exerciseSearchProvider);

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
            final query = controller.text.trim();
            // inicia a busca (debounce + requisição)
            ref.read(exerciseSearchProvider.notifier).updateQuery(query);

            if (query.isEmpty) {
              return [_buildEmptyState()];
            }

            // se já temos resultados prontos para essa query, devolve imediatamente
            final currentState = ref.read(exerciseSearchProvider);
            if (!currentState.isLoading && currentState.query == query) {
              return _buildSuggestions(currentState.results, controller, query);
            }

            // caso contrário aguardamos até que a busca termine (ou timeout)
            final timeout = const Duration(seconds: 2);
            final end = DateTime.now().add(timeout);
            List<SearchExercise> results = [];

            while (DateTime.now().isBefore(end)) {
              await Future.delayed(const Duration(milliseconds: 50));
              final st = ref.read(exerciseSearchProvider);
              if (st.query == query && !st.isLoading) {
                results = st.results;
                break;
              }
            }

            // fallback para o estado atual caso tenha expirado o timeout
            if (results.isEmpty) {
              results = ref.read(exerciseSearchProvider).results;
            }

            if (results.isEmpty) {
              return [_buildNoResultsState(controller, query)];
            }

            return _buildSuggestions(results, controller, query);
          },
    );
  }

  void _onSearchChanged(String value) {
    ref.read(exerciseSearchProvider.notifier).updateQuery(value);
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
          // Adiciona pequeno delay para permitir finalização das animações do SearchAnchor
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              widget.onExerciseSelected?.call(exercise);
            }
          });
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
              final created = await ref
                  .read(exerciseSearchProvider.notifier)
                  .createExercise(query);
              if (created != null) {
                if (mounted) {
                  controller.closeView(created.name);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      widget.onExerciseSelected?.call(created);
                    }
                  });
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao criar exercício'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.add),
            label: Text("Criar exercício '$query'"),
          ),
        ],
      ),
    );
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
