import 'package:flutter/material.dart';
import '../../domain/entities/exercise_set_history.dart';

class ExerciseHistoryModal extends StatelessWidget {
  final ExerciseSetHistory history;
  final String exerciseName;

  const ExerciseHistoryModal({
    super.key,
    required this.history,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF9C27B0), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Último treino — $exerciseName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (history.sessionDate != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatDate(history.sessionDate!),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 16),
          if (!history.hasHistory)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum histórico ainda.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...history.sets.asMap().entries.map((entry) {
              final idx = entry.key;
              final set = entry.value;
              return _buildSetRow(context, idx, set);
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, int index, WorkoutSet set) {
    final label = set.label ?? 'Série ${index + 1}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCE93D8), width: 1),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7B1FA2),
            ),
          ),
          const Spacer(),
          Text(
            set.displayText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B1FA2),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}

void showExerciseHistoryModal(
  BuildContext context, {
  required ExerciseSetHistory history,
  required String exerciseName,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) =>
        ExerciseHistoryModal(history: history, exerciseName: exerciseName),
  );
}
