import 'package:flutter/material.dart';

import 'package:iron_log/features/workout_day/domain/entities/technique_block.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_type.dart';
import 'package:iron_log/features/workout_day/presentation/exercise_card_styles.dart';
import 'package:iron_log/features/workout_day/presentation/workout_test_keys.dart';

class TechniqueHeader extends StatelessWidget {
  final TechniqueBlock block;
  final VoidCallback? onAddDrop;
  final VoidCallback? onAddCluster;
  final VoidCallback? onEditClusterRest;
  final VoidCallback? onRemoveTechnique;
  final VoidCallback? onAddTechnique;

  const TechniqueHeader({
    super.key,
    required this.block,
    this.onAddDrop,
    this.onAddCluster,
    this.onEditClusterRest,
    this.onRemoveTechnique,
    this.onAddTechnique,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (block.showHeader)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: ExerciseCardStyles.techniqueBlockDecoration(),
                child: Text(
                  block.label ?? block.type.displayLabel,
                  style: ExerciseCardStyles.techniqueHeaderStyle,
                ),
              ),
            ),
          if (block.showHeader) const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: _buildActions(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (block.type == TechniqueType.drop) {
      return [
        _TechniqueActionChip(
          label: '+ Drop',
          icon: Icons.trending_down_rounded,
          onTap: onAddDrop,
        ),
        _TechniqueActionChip(
          label: 'Remover',
          icon: Icons.close_rounded,
          onTap: onRemoveTechnique,
          destructive: true,
        ),
      ];
    }

    if (block.type.isGrouped) {
      return [
        _TechniqueActionChip(
          label: 'Remover técnica',
          icon: Icons.close_rounded,
          onTap: onRemoveTechnique,
          destructive: true,
        ),
      ];
    }

    return [
      _TechniqueActionChip(
        key: WorkoutTestKeys.techniqueMenu,
        label: '+ Técnica',
        icon: Icons.bolt_rounded,
        onTap: onAddTechnique,
        emphasized: true,
      ),
    ];
  }
}

class _TechniqueActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;
  final bool emphasized;

  const _TechniqueActionChip({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.destructive = false,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = destructive
        ? const Color(0xFFE53935)
        : ExerciseCardStyles.accent;
    final bg = destructive
        ? const Color(0x14E53935)
        : emphasized
        ? ExerciseCardStyles.accentChipBg
        : ExerciseCardStyles.accentBg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: enabled ? bg : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? fg.withValues(alpha: emphasized ? 0.35 : 0.2)
                  : Colors.grey.shade300,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: enabled ? fg : ExerciseCardStyles.labelMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: enabled ? fg : ExerciseCardStyles.labelMuted,
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
