import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/auth_service.dart';
import '../../domain/entities/search_exercise.dart';

/// DEPRECATED: Use UnifiedExerciseSearch from core/components/exercise_search instead
/// Provider para gerenciar a busca de exercícios
@Deprecated('Use unifiedExerciseSearchQueryProvider from UnifiedExerciseSearch')
final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');
@Deprecated(
  'Use unifiedExerciseSearchResultsProvider from UnifiedExerciseSearch',
)
final exerciseSearchResultsProvider = StateProvider<List<SearchExercise>>(
  (ref) => [],
);
// IDs dos exercícios selecionados na sessão atual (compartilhado entre busca e selecionados)
@Deprecated('Use local state management or UnifiedExerciseSearch providers')
final selectedExerciseIdsProvider = StateProvider<Set<String>>(
  (ref) => <String>{},
);
// Objetos completos dos exercícios selecionados
@Deprecated('Use local state management or UnifiedExerciseSearch providers')
final selectedExercisesProvider = StateProvider<List<SearchExercise>>(
  (ref) => [],
);

/// DEPRECATED: Use UnifiedExerciseSearch from core/components/exercise_search instead
@Deprecated('Use UnifiedExerciseSearch instead')
class ExerciseSearchField extends ConsumerStatefulWidget {
  const ExerciseSearchField({super.key});

  @override
  ConsumerState<ExerciseSearchField> createState() =>
      _ExerciseSearchFieldState();
}

class _ExerciseSearchFieldState extends ConsumerState<ExerciseSearchField> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(exerciseSearchQueryProvider);

    return TextField(
      onChanged: (value) {
        ref.read(exerciseSearchQueryProvider.notifier).state = value;
        _onSearchChanged(value);
      },
      decoration: InputDecoration(
        hintText: 'Digite o nome do exercício...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  ref.read(exerciseSearchQueryProvider.notifier).state = '';
                  ref.read(exerciseSearchResultsProvider.notifier).state = [];
                  _debounceTimer?.cancel();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  void _onSearchChanged(String query) {
    // Cancela o timer anterior se existir
    _debounceTimer?.cancel();

    // Se a query estiver vazia, limpa os resultados imediatamente
    if (query.isEmpty) {
      ref.read(exerciseSearchResultsProvider.notifier).state = [];
      return;
    }

    // Cria um novo timer com debounce de 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    if (query.length < 2) {
      ref.read(exerciseSearchResultsProvider.notifier).state = [];
      return;
    }

    try {
      final auth = AuthService();
      // Garante interceptors e baseUrl
      auth.initialize();
      final response = await auth.authenticatedRequest(
        method: 'GET',
        path: '/exercises/search',
        queryParameters: {'q': query, 'limit': 30},
      );
      final results = (response.data as List)
          .cast<Map<String, dynamic>>()
          .map((json) => SearchExercise.fromJson(json))
          .toList();
      ref.read(exerciseSearchResultsProvider.notifier).state = results;
    } catch (e) {
      // Em caso de erro, limpa resultados e exibe feedback mínimo via log
      ref.read(exerciseSearchResultsProvider.notifier).state = [];
    }
  }
}
