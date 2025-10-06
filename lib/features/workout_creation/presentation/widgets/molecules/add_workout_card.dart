import 'package:flutter/material.dart';
import '../atoms/dashed_container.dart';
import '../atoms/add_icon.dart';

/// Molecule: Add workout card that combines dashed container with add icon and text
class AddWorkoutCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final String? subtitle;

  const AddWorkoutCard({
    super.key,
    this.onTap,
    this.title = 'Adicionar treino',
    this.subtitle = 'Criar novo split',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: DashedContainer(
        onTap: onTap,
        child: Row(
          children: [
            // Add icon with background
            AddIcon(
              size: 24,
              withBackground: true,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
