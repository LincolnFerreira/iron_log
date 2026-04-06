import 'package:flutter/material.dart';
import '../../../domain/entities/routine.dart';

/// Card de rotina exibido na lista de rotinas do usuário.
///
/// Exibe o nome, divisão, exercícios resumidos e, quando aplicável,
/// o chip "Ativo" indicando a rotina correntemente selecionada.
class RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback? onTap;
  final VoidCallback? onSetActive;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    this.onTap,
    this.onSetActive,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final exerciseNames = routine.sessions
        .expand((s) => s.exercises)
        .map((e) => e.exercise.name)
        .toList();
    final description = exerciseNames.isEmpty
        ? 'Nenhum exercício adicionado'
        : exerciseNames.join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      routine.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Active chip — própria linha, logo abaixo do nome
                    if (routine.isActive) ...[
                      const SizedBox(height: 5),
                      _ActiveChip(colorScheme: colorScheme),
                    ],
                    if (routine.division != null &&
                        routine.division!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        routine.division!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Session count chips
                    if (routine.sessions.isNotEmpty)
                      _SessionCountRow(
                        routine: routine,
                        colorScheme: colorScheme,
                      ),
                  ],
                ),
              ),
              // Popup menu
              PopupMenuButton<_RoutineAction>(
                onSelected: (action) {
                  switch (action) {
                    case _RoutineAction.setActive:
                      onSetActive?.call();
                    case _RoutineAction.edit:
                      onEdit?.call();
                    case _RoutineAction.delete:
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (!routine.isActive)
                    const PopupMenuItem(
                      value: _RoutineAction.setActive,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Definir como ativa'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: _RoutineAction.edit,
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: _RoutineAction.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Excluir'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RoutineAction { setActive, edit, delete }

class _ActiveChip extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ActiveChip({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: colorScheme.primary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 11, color: colorScheme.primary),
          const SizedBox(width: 3),
          Text(
            'Ativo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCountRow extends StatelessWidget {
  final Routine routine;
  final ColorScheme colorScheme;

  const _SessionCountRow({required this.routine, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final sessionCount = routine.sessions.length;
    final exerciseCount = routine.sessions.fold<int>(
      0,
      (sum, s) => sum + s.exercises.length,
    );

    return Row(
      children: [
        _InfoChip(
          icon: Icons.calendar_view_week_outlined,
          label: '$sessionCount sessão${sessionCount != 1 ? 'ões' : ''}',
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 6),
        _InfoChip(
          icon: Icons.fitness_center_outlined,
          label: '$exerciseCount exercício${exerciseCount != 1 ? 's' : ''}',
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.onSurface.withOpacity(0.45)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
