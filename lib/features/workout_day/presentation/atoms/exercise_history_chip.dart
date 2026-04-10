import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/exercise_set_history.dart';

class ExerciseHistoryChip extends StatelessWidget {
  final AsyncValue<ExerciseSetHistory> historyAsync;
  final VoidCallback? onTap;

  const ExerciseHistoryChip({
    super.key,
    required this.historyAsync,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (historyAsync.isLoading) {
      return _buildChip(
        label: '⏳',
        borderColor: Colors.grey.shade300,
        backgroundColor: Colors.grey.shade100,
        textColor: Colors.grey.shade500,
        onTap: null,
      );
    }

    if (historyAsync.hasError) {
      return _buildChip(
        label: 'Sem histórico',
        borderColor: Colors.grey.shade300,
        backgroundColor: Colors.grey.shade100,
        textColor: Colors.grey.shade500,
        onTap: null,
      );
    }

    final history = historyAsync.value;

    if (history == null || !history.hasHistory) {
      return _buildChip(
        label: 'Sem histórico',
        borderColor: Colors.grey.shade300,
        backgroundColor: Colors.grey.shade100,
        textColor: Colors.grey.shade500,
        onTap: null,
      );
    }

    final lastSet = history.sets.last;

    return _buildChip(
      label: lastSet.displayText,
      borderColor: const Color(0xFF9C27B0),
      backgroundColor: const Color(0xFFF3E5F5),
      textColor: const Color(0xFF7B1FA2),
      onTap: onTap,
    );
  }

  Widget _buildChip({
    required String label,
    required Color borderColor,
    required Color backgroundColor,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
