import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';

class SavedSessionsSection extends StatelessWidget {
  final List<Session> sessions;
  final Session? selectedSession;
  final void Function(Session) onSelectSession;

  const SavedSessionsSection({
    super.key,
    required this.sessions,
    required this.onSelectSession,
    this.selectedSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SESSÕES DA ROTINA',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        if (sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Nenhuma sessão encontrada',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          )
        else
          ...sessions.map((session) {
            final isSelected = session.id == selectedSession?.id;
            return _SessionSelectCard(
              session: session,
              isSelected: isSelected,
              onTap: () => onSelectSession(session),
            );
          }),
      ],
    );
  }
}

class _SessionSelectCard extends StatelessWidget {
  final Session session;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionSelectCard({
    required this.session,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? AppColors.primaryLight.withOpacity(0.06)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryLight.withOpacity(0.4)
                    : theme.colorScheme.outline.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight.withOpacity(0.14)
                        : AppColors.primaryLight.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 20,
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.primaryLight.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primaryLight
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (session.muscles.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          session.muscles.join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.55,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 22,
                    color: AppColors.primaryLight,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurface.withOpacity(0.25),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
