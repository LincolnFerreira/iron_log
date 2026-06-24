import 'package:flutter/material.dart';

import '../../domain/entities/effort_type.dart';
import '../../domain/entities/parsed_workout_import.dart';

class ImportSessionCard extends StatelessWidget {
  const ImportSessionCard({
    super.key,
    required this.session,
    required this.child,
    this.onRemove,
  });

  final ParsedImportSession session;
  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title ?? 'Sessão',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (session.dateConfidence == ConfidenceLevel.undetermined)
                  Chip(
                    label: const Text('Data não determinada'),
                    visualDensity: VisualDensity.compact,
                  ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onRemove,
                  ),
              ],
            ),
            if (session.sessionNotes != null && session.sessionNotes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  session.sessionNotes!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
