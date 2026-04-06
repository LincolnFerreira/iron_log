import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';

class SessionPickerSheet extends StatelessWidget {
  final List<Session> sessions;
  final Session? currentSession;
  final void Function(Session) onSelectSession;

  const SessionPickerSheet({
    super.key,
    required this.sessions,
    required this.onSelectSession,
    this.currentSession,
  });

  static void show(
    BuildContext context, {
    required List<Session> sessions,
    Session? currentSession,
    required void Function(Session) onSelectSession,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SessionPickerSheet(
        sessions: sessions,
        currentSession: currentSession,
        onSelectSession: onSelectSession,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Escolher sessão',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sessions.map(
            (session) => _SessionPickerItem(
              session: session,
              isSelected: session.id == currentSession?.id,
              onTap: () {
                onSelectSession(session);
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SessionPickerItem extends StatelessWidget {
  final Session session;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionPickerItem({
    required this.session,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.4)
                : theme.colorScheme.outline.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        tileColor: isSelected
            ? AppColors.primaryLight.withValues(alpha: 0.06)
            : Colors.transparent,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.14)
                : AppColors.primaryLight.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.fitness_center,
            size: 20,
            color: isSelected
                ? AppColors.primaryLight
                : AppColors.primaryLight.withValues(alpha: 0.5),
          ),
        ),
        title: Text(
          session.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected
                ? AppColors.primaryLight
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: session.muscles.isNotEmpty
            ? Text(
                session.muscles.join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: isSelected
            ? Icon(
                Icons.check_circle_rounded,
                size: 22,
                color: AppColors.primaryLight,
              )
            : Icon(
                Icons.radio_button_unchecked_rounded,
                size: 22,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              ),
      ),
    );
  }
}
