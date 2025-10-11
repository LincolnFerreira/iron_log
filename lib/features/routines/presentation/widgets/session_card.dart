import 'package:flutter/material.dart';
import '../../domain/entities/routine.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback? onTap;
  final VoidCallback? onMenuPressed;
  final bool isDraggable;

  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.onMenuPressed,
    this.isDraggable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        color: theme.colorScheme.surface,
        child: Row(
          children: [
            // Drag handle - só mostra se for draggable
            if (isDraggable)
              ReorderableDragStartListener(
                index: 0, // será sobrescrito pelo ReorderableListView
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    Icons.drag_indicator,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                    size: 24,
                  ),
                ),
              )
            else
              const SizedBox(width: 16), // Espaço reservado
            // Conteúdo clicável
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Espaço para o drag handle quando não é draggable
                      if (!isDraggable) const SizedBox(width: 24),
                      const SizedBox(width: 12),

                      // Session icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Session info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${session.exercises.length} exercícios',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: session.muscles.map((muscle) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    muscle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      // Menu button
                      if (onMenuPressed != null)
                        IconButton(
                          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                          onPressed: onMenuPressed,
                        )
                      else
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
