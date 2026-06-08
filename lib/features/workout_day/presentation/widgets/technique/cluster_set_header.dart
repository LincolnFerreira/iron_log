import 'package:flutter/material.dart';

import 'package:iron_log/features/workout_day/domain/entities/technique_block.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_type.dart';
import 'package:iron_log/features/workout_day/domain/mappers/technique_block_mapper.dart';
import 'package:iron_log/features/workout_day/presentation/exercise_card_styles.dart';

/// Badge compacta + menu ⋯ que fica no topo da área filho do cluster.
class ClusterSetHeader extends StatelessWidget {
  final TechniqueBlock block;
  final int? anchorSeriesNumber;
  final VoidCallback? onAddCluster;
  final VoidCallback? onEditClusterRest;
  final VoidCallback? onClusterDrop;
  final VoidCallback? onTerminateCluster;
  final VoidCallback? onRemoveTechnique;

  const ClusterSetHeader({
    super.key,
    required this.block,
    this.anchorSeriesNumber,
    this.onAddCluster,
    this.onEditClusterRest,
    this.onClusterDrop,
    this.onTerminateCluster,
    this.onRemoveTechnique,
  });

  @override
  Widget build(BuildContext context) {
    final badge = TechniqueBlockMapper.clusterBadgeText(block);
    final showTerminate =
        !block.terminatedEarly && onTerminateCluster != null;
    final label = block.label ?? TechniqueType.cluster.displayLabel;
    final badgeText = [label, if (badge.isNotEmpty) badge].join(' · ');

    return Row(
      children: [
        // Badge pill compacta
        Expanded(
          child: GestureDetector(
            onTap: onEditClusterRest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ExerciseCardStyles.accentBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeText,
                style: ExerciseCardStyles.techniqueHeaderStyle.copyWith(
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Remover como text link leve
        GestureDetector(
          onTap: onRemoveTechnique,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'Remover',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE53935).withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        // Menu ⋯ para ações secundárias
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_horiz_rounded,
            size: 18,
            color: ExerciseCardStyles.labelMuted,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onSelected: (value) {
            switch (value) {
              case 'add_cluster':
                onAddCluster?.call();
              case 'rest':
                onEditClusterRest?.call();
              case 'drop':
                onClusterDrop?.call();
              case 'terminate':
                onTerminateCluster?.call();
            }
          },
          itemBuilder: (context) => [
            if (!block.terminatedEarly)
              const PopupMenuItem(
                value: 'add_cluster',
                child: Text('+ Cluster'),
              ),
            const PopupMenuItem(
              value: 'rest',
              child: Text('Descanso'),
            ),
            if (!block.terminatedEarly)
              const PopupMenuItem(
                value: 'drop',
                child: Text('+ Drop'),
              ),
            if (showTerminate)
              const PopupMenuItem(
                value: 'terminate',
                child: Text('Encerrar cluster'),
              ),
          ],
        ),
      ],
    );
  }
}
