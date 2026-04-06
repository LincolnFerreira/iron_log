import 'package:flutter/material.dart';

/// Cabeçalho de grupo mensal na lista de histórico.
/// Exibe "Mês Ano" + "N treinos · Xkg vol."
class HistoryMonthHeader extends StatelessWidget {
  final String monthLabel;
  final int workoutCount;
  final double totalVolume;

  const HistoryMonthHeader({
    super.key,
    required this.monthLabel,
    required this.workoutCount,
    required this.totalVolume,
  });

  String get _volumeText {
    if (totalVolume <= 0) return '';
    if (totalVolume >= 1000) {
      return ' · ${(totalVolume / 1000).toStringAsFixed(1)}t vol.';
    }
    return ' · ${totalVolume.toStringAsFixed(0)}kg vol.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            monthLabel,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(
            '$workoutCount treino${workoutCount != 1 ? 's' : ''}$_volumeText',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
