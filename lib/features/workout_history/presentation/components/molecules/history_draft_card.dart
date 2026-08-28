import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_draft.dart';

/// Card de rascunho local no Histórico (treino/registro ainda não finalizado).
class HistoryDraftCard extends StatelessWidget {
  final WorkoutDraftSummary draft;
  final VoidCallback onContinue;

  const HistoryDraftCard({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = draft.sessionName.trim().isEmpty
        ? 'Treino em andamento'
        : draft.sessionName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onContinue,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RASCUNHO',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${draft.exerciseCount} exercício${draft.exerciseCount != 1 ? 's' : ''} • tocar para continuar',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
