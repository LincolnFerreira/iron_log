import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/serie_log.dart';
import '../atoms/type_badge.dart';
import '../atoms/status_icon.dart';

/// A summary row displaying a completed series in workout history/summary screens.
/// Read-only display of series data with animated transitions and visual status indicators.
class SeriesSummaryRow extends StatelessWidget {
  final SerieLog serie;
  final bool animated;

  const SeriesSummaryRow({super.key, required this.serie, this.animated = true});

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: serie.status == 'completed'
            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Número da série + Type Badge
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Série ${serie.serieNumber}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TypeBadge(type: serie.type, animated: animated),
              ],
            ),
          ),
          // Peso, Reps e RIR
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      serie.weight,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('×', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    Text(
                      serie.reps,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (serie.rir != '--')
                  Text(
                    'RIR ${serie.rir}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          // Status Icon
          Expanded(
            flex: 1,
            child: StatusIcon(status: serie.status, animated: animated),
          ),
        ],
      ),
    );

    if (!animated) {
      return row;
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: AlwaysStoppedAnimation(1.0),
          curve: Curves.easeOut,
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: AlwaysStoppedAnimation(1.0),
                curve: Curves.easeOut,
              ),
            ),
        child: row,
      ),
    );
  }
}
