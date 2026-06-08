import 'package:flutter/material.dart';

import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_block.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_type.dart';
import 'package:iron_log/features/workout_day/domain/entities/weight_unit.dart';
import 'package:iron_log/features/workout_day/presentation/exercise_card_styles.dart';

import '../../molecules/series_table.dart';
import '../../series_visual_style.dart';
import 'cluster_set_footer.dart';
import 'cluster_set_header.dart';
import 'technique_header.dart';

class TechniqueBlockCard extends StatelessWidget {
  final TechniqueBlock block;
  final int blockIndex;
  final int globalSeriesOffset;
  final String weight;
  final String reps;
  final WeightUnit weightUnit;
  final ValueChanged<List<SeriesEntry>> onEntriesChanged;
  final void Function(int globalIndex, bool done)? onToggleDone;
  final ValueChanged<int>? onSeriesRowInteract;
  final VoidCallback? onAddDrop;
  final VoidCallback? onAddCluster;
  final VoidCallback? onClusterDrop;
  final VoidCallback? onEditClusterRest;
  final VoidCallback? onRemoveTechnique;
  final VoidCallback? onAddTechnique;
  final VoidCallback? onTerminateCluster;
  final bool showColumnHeader;
  final bool attachesToPreviousSeries;
  final bool followedByCluster;
  final int? clusterAnchorSeries;

  const TechniqueBlockCard({
    super.key,
    required this.block,
    required this.blockIndex,
    required this.globalSeriesOffset,
    required this.weight,
    required this.reps,
    required this.weightUnit,
    required this.onEntriesChanged,
    this.onToggleDone,
    this.onSeriesRowInteract,
    this.onAddDrop,
    this.onAddCluster,
    this.onClusterDrop,
    this.onEditClusterRest,
    this.onRemoveTechnique,
    this.onAddTechnique,
    this.onTerminateCluster,
    this.showColumnHeader = false,
    this.attachesToPreviousSeries = false,
    this.followedByCluster = false,
    this.clusterAnchorSeries,
  });

  bool get _isCluster => block.type == TechniqueType.cluster;

  SeriesVisualStyle get _visualStyle {
    if (block.type.isGrouped && block.type != TechniqueType.cluster) {
      return SeriesVisualStyle.compactExecution;
    }
    return SeriesVisualStyle.standard;
  }

  Widget _buildSeriesTable({required bool showHeader}) {
    return SeriesTable(
      count: block.entries.length,
      weight: weight,
      reps: reps,
      weightUnit: weightUnit,
      entries: block.entries,
      showColumnHeader: showHeader,
      hideTypeForDerived: true,
      hideTypeForCluster: _isCluster,
      clusterRestSeconds: _isCluster ? block.restBetweenMiniSets : null,
      seriesKeyOffset: globalSeriesOffset,
      visualStyle: _visualStyle,
      showTerminateCluster: false,
      clusterTerminatedEarly: block.terminatedEarly,
      onTerminateCluster: onTerminateCluster,
      onEntriesChanged: onEntriesChanged,
      onToggleDone: (localIndex, done) {
        onToggleDone?.call(globalSeriesOffset + localIndex, done);
      },
      onSeriesRowInteract: (localIndex) {
        onSeriesRowInteract?.call(globalSeriesOffset + localIndex);
      },
    );
  }

  Widget _buildClusterFooter() {
    final primaryEntries = block.entries
        .where((e) => !e.isDerived)
        .toList(growable: false);
    return ClusterSetFooter(
      doneCount: primaryEntries.where((e) => e.done).length,
      totalCount: primaryEntries.length,
      onRemove: onRemoveTechnique,
    );
  }

  /// Área filho do cluster: linha vertical esquerda + conteúdo indentado.
  Widget _buildClusterChildArea() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Linha vertical lateral — conecta pai → filhos
          Container(
            width: ExerciseCardStyles.clusterTreeLineWidth,
            margin: const EdgeInsets.only(top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: ExerciseCardStyles.clusterTreeLineColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: ExerciseCardStyles.clusterChildIndent),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClusterSetHeader(
                  block: block,
                  anchorSeriesNumber: clusterAnchorSeries,
                  onAddCluster: onAddCluster,
                  onEditClusterRest: onEditClusterRest,
                  onClusterDrop: onClusterDrop,
                  onTerminateCluster: onTerminateCluster,
                  onRemoveTechnique: onRemoveTechnique,
                ),
                const SizedBox(height: 8),
                _buildSeriesTable(showHeader: false),
                _buildClusterFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (block.entries.isEmpty) return const SizedBox.shrink();

    if (_isCluster) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildClusterChildArea(),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: block.showHeader ? 4 : 0,
        bottom: followedByCluster ? 4 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TechniqueHeader(
            block: block,
            onAddDrop: onAddDrop,
            onAddCluster: onAddCluster,
            onEditClusterRest: onEditClusterRest,
            onRemoveTechnique: onRemoveTechnique,
            onAddTechnique: onAddTechnique,
          ),
          if (block.showHeader) const SizedBox(height: 2),
          _buildSeriesTable(showHeader: showColumnHeader),
        ],
      ),
    );
  }
}
