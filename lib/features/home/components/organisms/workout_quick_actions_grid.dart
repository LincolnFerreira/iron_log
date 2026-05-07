import 'package:flutter/material.dart';

/// Quick action buttons grid displaying common workout actions
/// Shows "Minhas Rotinas", "Novas Rotinas", and "Criar Rápido" as simple action cards
class WorkoutQuickActionsGrid extends StatelessWidget {
  final VoidCallback onMyRoutinesTap;
  final VoidCallback onNewRoutinesTap;
  final VoidCallback onQuickCreateTap;

  const WorkoutQuickActionsGrid({
    super.key,
    required this.onMyRoutinesTap,
    required this.onNewRoutinesTap,
    required this.onQuickCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          'AÇÕES RÁPIDAS',
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        // Action cards row
        Row(
          spacing: 12,
          children: [
            // Minhas Rotinas
            Expanded(
              child: _QuickActionCard(
                icon: Icons.library_books,
                label: 'Minhas Rotinas',
                subtitle: 'Acompanhe seus treinos',
                onTap: onMyRoutinesTap,
              ),
            ),
            // Novas Rotinas
            Expanded(
              child: _QuickActionCard(
                icon: Icons.flash_on,
                label: 'Novas Rotinas',
                subtitle: 'Descubra novos treinos',
                onTap: onNewRoutinesTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual quick action card with icon and label
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary.withValues(alpha: isDark ? .22 : .14),
                        primary.withValues(alpha: isDark ? .10 : .06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isDark ? primary.withValues(alpha: .92) : primary,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: isDark ? .72 : .62,
                    ),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
