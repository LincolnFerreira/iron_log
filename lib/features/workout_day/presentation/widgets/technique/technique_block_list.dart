import 'package:flutter/material.dart';

import 'package:iron_log/features/workout_day/domain/entities/technique_block.dart';

import 'package:iron_log/features/workout_day/domain/entities/technique_type.dart';

import 'package:iron_log/features/workout_day/domain/entities/weight_unit.dart';

import 'package:iron_log/features/workout_day/domain/mappers/technique_block_mapper.dart';



import 'cluster_config_sheet.dart';

import 'technique_block_card.dart';



class TechniqueBlockList extends StatelessWidget {

  final List<TechniqueBlock> blocks;

  final String weight;

  final String reps;

  final WeightUnit weightUnit;

  final ValueChanged<List<TechniqueBlock>> onBlocksChanged;

  final void Function(int globalIndex, bool done)? onToggleDone;

  final ValueChanged<int>? onSeriesRowInteract;



  const TechniqueBlockList({

    super.key,

    required this.blocks,

    required this.weight,

    required this.reps,

    required this.weightUnit,

    required this.onBlocksChanged,

    this.onToggleDone,

    this.onSeriesRowInteract,

  });



  int _offsetForBlock(int blockIndex) {

    var offset = 0;

    for (var i = 0; i < blockIndex; i++) {

      offset += blocks[i].entries.length;

    }

    return offset;

  }



  void _updateBlock(int index, TechniqueBlock updated) {

    final next = [...blocks];

    next[index] = updated;

    onBlocksChanged(next);

  }



  void _showTechniqueSheet(BuildContext context, int blockIndex) {

    showModalBottomSheet<void>(

      context: context,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),

      ),

      builder: (ctx) => SafeArea(

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            ListTile(

              title: const Text('Aquecimento'),

              onTap: () {

                Navigator.pop(ctx);

                _applyTechnique(blockIndex, TechniqueType.warmup);

              },

            ),

            ListTile(

              title: const Text('Drop Set'),

              onTap: () {

                Navigator.pop(ctx);

                _applyTechnique(blockIndex, TechniqueType.drop);

              },

            ),

            ListTile(

              title: const Text('Cluster Set'),

              onTap: () async {

                Navigator.pop(ctx);

                await _applyClusterTechnique(context, blockIndex);

              },

            ),

          ],

        ),

      ),

    );

  }



  Future<void> _applyClusterTechnique(

    BuildContext context,

    int blockIndex,

  ) async {

    final config = await showClusterConfigSheet(

      context,

      weight: weight,

      reps: reps,

    );

    if (config == null) return;



    onBlocksChanged(

      TechniqueBlockMapper.applyClusterTechnique(

        blocks,

        blockIndex,

        defaultWeight: weight,

        defaultReps: reps,

        miniSetCount: config.miniSetCount,

        repsPerMiniSet: config.repsPerMiniSet,

        restBetweenMiniSets: config.restBetweenMiniSets,

      ),

    );

  }



  void _applyTechnique(int blockIndex, TechniqueType type) {

    if (type == TechniqueType.drop) {

      onBlocksChanged(

        TechniqueBlockMapper.applyDropTechnique(

          blocks,

          blockIndex,

          defaultWeight: weight,

          defaultReps: reps,

        ),

      );

      return;

    }



    if (type == TechniqueType.warmup) {

      final block = blocks[blockIndex];

      _updateBlock(

        blockIndex,

        block.copyWith(

          type: TechniqueType.warmup,

          entries: block.entries

              .map((e) => e.copyWith(type: 0))

              .toList(growable: false),

        ),

      );

    }

  }



  void _addDrop(int blockIndex) {

    onBlocksChanged(

      TechniqueBlockMapper.appendDropSet(

        blocks,

        blockIndex,

        defaultWeight: weight,

        defaultReps: reps,

      ),

    );

  }



  void _addCluster(int blockIndex) {

    onBlocksChanged(

      TechniqueBlockMapper.appendClusterMiniSet(

        blocks,

        blockIndex,

        defaultWeight: weight,

        defaultReps: reps,

      ),

    );

  }



  void _addClusterDrop(int blockIndex) {

    onBlocksChanged(

      TechniqueBlockMapper.appendClusterDrop(

        blocks,

        blockIndex,

        defaultWeight: weight,

        defaultReps: reps,

      ),

    );

  }



  void _terminateCluster(int blockIndex) {

    onBlocksChanged(

      TechniqueBlockMapper.terminateClusterEarly(blocks, blockIndex),

    );

  }



  Future<void> _editClusterRest(BuildContext context, int blockIndex) async {

    final block = blocks[blockIndex];

    final current = block.restBetweenMiniSets ??

        TechniqueBlockMapper.defaultClusterRestSeconds;



    final picked = await showModalBottomSheet<int>(

      context: context,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),

      ),

      builder: (ctx) => SafeArea(

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            const Padding(

              padding: EdgeInsets.all(16),

              child: Text(

                'Descanso entre clusters',

                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),

              ),

            ),

            for (final seconds in [15, 20, 30, 45])

              ListTile(

                title: Text('${seconds}s'),

                trailing: current == seconds

                    ? const Icon(Icons.check, color: Color(0xFF5B5FE9))

                    : null,

                onTap: () => Navigator.pop(ctx, seconds),

              ),

          ],

        ),

      ),

    );



    if (picked == null) return;

    _updateBlock(blockIndex, block.copyWith(restBetweenMiniSets: picked));

  }



  void _removeTechnique(int blockIndex) {

    final block = blocks[blockIndex];

    _updateBlock(

      blockIndex,

      block.copyWith(

        type: TechniqueType.normal,

        label: null,

        restBetweenMiniSets: null,

        terminatedEarly: false,

        entries: block.entries

            .where((e) => !e.isDerived)

            .map(

              (e) => e.copyWith(

                isDerived: false,

                miniSetIndex: null,

                setType: null,

              ),

            )

            .toList(),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    if (blocks.isEmpty) return const SizedBox.shrink();



    return Column(

      children: blocks.asMap().entries.map((entry) {

        final index = entry.key;

        final block = entry.value;

        final attachesToPrevious = index > 0 &&
            blocks[index - 1].type == TechniqueType.normal &&
            block.type == TechniqueType.cluster;
        final followedByCluster = index < blocks.length - 1 &&
            block.type == TechniqueType.normal &&
            blocks[index + 1].type == TechniqueType.cluster;
        final globalOffset = _offsetForBlock(index);

        return TechniqueBlockCard(

          key: ValueKey('block_${block.id ?? '$index-${block.type.name}'}'),

          block: block,

          blockIndex: index,

          globalSeriesOffset: globalOffset,

          weight: weight,

          reps: reps,

          weightUnit: weightUnit,

          showColumnHeader: index == 0,

          attachesToPreviousSeries: attachesToPrevious,

          followedByCluster: followedByCluster,

          clusterAnchorSeries:
              attachesToPrevious ? globalOffset + 1 : null,

          onEntriesChanged: (entries) {

            _updateBlock(index, block.copyWith(entries: entries));

          },

          onToggleDone: onToggleDone,

          onSeriesRowInteract: onSeriesRowInteract,

          onAddDrop: () => _addDrop(index),

          onAddCluster: () => _addCluster(index),

          onClusterDrop: () => _addClusterDrop(index),

          onEditClusterRest: () => _editClusterRest(context, index),

          onRemoveTechnique: () => _removeTechnique(index),

          onAddTechnique: () => _showTechniqueSheet(context, index),

          onTerminateCluster: () => _terminateCluster(index),

        );

      }).toList(),

    );

  }

}


