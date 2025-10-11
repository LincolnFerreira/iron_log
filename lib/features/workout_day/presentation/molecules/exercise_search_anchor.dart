import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/auth_service.dart';

// Provider para gerenciar a busca de exercícios no SearchAnchor
final searchAnchorQueryProvider = StateProvider<String>((ref) => '');
final searchAnchorResultsProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

class ExerciseSearchAnchor extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>)? onExerciseSelected;

  const ExerciseSearchAnchor({super.key, this.onExerciseSelected});

  @override
  ConsumerState<ExerciseSearchAnchor> createState() =>
      _ExerciseSearchAnchorState();
}

class _ExerciseSearchAnchorState extends ConsumerState<ExerciseSearchAnchor> {
  final SearchController _searchController = SearchController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      isFullScreen: true,
      searchController: _searchController,
      builder: (BuildContext context, SearchController controller) {
        return Container(
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
            onTap: () {
              controller.openView();
            },
            decoration: InputDecoration(
              hintText: 'Buscar exercícios...',
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

            // Atualiza o provider com a query atual
            ref.read(searchAnchorQueryProvider.notifier).state = query;

            // Estado inicial - quando não há query
            if (query.isEmpty) {
              return [
                Padding(
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
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
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
                ),
              ];
            }

            // Cancela o timer anterior se existir
            _debounceTimer?.cancel();

            // Cria um novo timer com debounce de 300ms
            _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
              await _performSearch(query);
            });

            // Retorna os resultados atuais enquanto busca
            final currentResults = ref.read(searchAnchorResultsProvider);
            return _buildSuggestions(currentResults, controller, query);
          },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      ref.read(searchAnchorResultsProvider.notifier).state = [];
      return;
    }

    try {
      final auth = AuthService();
      auth.initialize();
      final response = await auth.authenticatedRequest(
        method: 'GET',
        path: '/exercises/search',
        queryParameters: {'q': query, 'limit': 30},
      );
      final results = (response.data as List).cast<Map<String, dynamic>>();
      ref.read(searchAnchorResultsProvider.notifier).state = results;
    } catch (e) {
      ref.read(searchAnchorResultsProvider.notifier).state = [];
    }
  }

  List<Widget> _buildSuggestions(
    List<Map<String, dynamic>> results,
    SearchController controller,
    String query,
  ) {
    // Estado inicial - quando não há query
    if (query.isEmpty) {
      return [
        Padding(
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
        ),
      ];
    }

    // Estado de carregamento/busca - quando há query mas ainda não tem resultados
    if (results.isEmpty && query.length >= 2) {
      return [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Buscando exercícios...',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    // Nenhum resultado encontrado
    if (results.isEmpty && query.length >= 2) {
      return [
        Padding(
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
            ],
          ),
        ),
      ];
    }

    // Resultados encontrados
    return results.map((exercise) {
      final name = exercise['name'] ?? 'Nome não disponível';
      final muscles = exercise['muscles'] ?? '';
      final category = exercise['category'] ?? '';

      return ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(category),
          child: Text(
            category.isNotEmpty ? category[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(muscles, style: TextStyle(color: Colors.grey.shade600)),
        onTap: () {
          controller.closeView(name);
          // Chamar callback com os dados do exercício selecionado
          if (widget.onExerciseSelected != null) {
            widget.onExerciseSelected!(exercise);
          }
        },
      );
    }).toList();
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
