import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/components/exercise_search/exercise_search.dart';
import '../../../../routines/domain/entities/search_exercise.dart';

class ExerciseSearchBar extends ConsumerWidget {
  final Function(SearchExercise)? onExerciseSelected;

  const ExerciseSearchBar({super.key, this.onExerciseSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: UnifiedExerciseSearch(
        hintText: 'Buscar exercícios...',
        onExerciseSelected: onExerciseSelected,
        useSearchAnchor: true,
      ),
    );
  }
}
