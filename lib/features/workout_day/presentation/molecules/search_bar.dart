import 'package:flutter/material.dart';
import 'package:iron_log/core/components/exercise_search/exercise_search.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';

/// SearchBar refatorado para usar o componente unificado de busca
/// TODO: Este componente pode ser removido futuramente, use UnifiedExerciseSearch diretamente
@Deprecated('Use UnifiedExerciseSearch diretamente')
class SearchBar extends StatelessWidget {
  final String hintText;
  final Function(SearchExercise)? onExerciseSelected;

  const SearchBar({
    super.key,
    this.hintText = 'Buscar exercícios...',
    this.onExerciseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedExerciseSearch(
      hintText: hintText,
      onExerciseSelected: onExerciseSelected,
      useSearchAnchor: true,
    );
  }
}
