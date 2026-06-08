import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_block.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_type.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

class TechniqueBlockMapper {
  static const defaultClusterRestSeconds = 20;
  static const defaultClusterMiniSetCount = 3;
  static const defaultClusterRepsPerMiniSet = 2;

  /// Ensures [exercise] has at least one block. Synthesizes NORMAL from flat entries.
  static List<TechniqueBlock> ensureBlocks(WorkoutExercise exercise) {
    if (exercise.blocks.isNotEmpty) return exercise.blocks;
    if (exercise.entries.isNotEmpty) {
      return [
        TechniqueBlock(
          type: TechniqueType.normal,
          order: 0,
          entries: List<SeriesEntry>.from(exercise.entries),
        ),
      ];
    }
    final count = exercise.series > 0 ? exercise.series : 1;
    return [
      TechniqueBlock(
        type: TechniqueType.normal,
        order: 0,
        entries: List.generate(
          count,
          (i) => SeriesEntry(
            index: i,
            weight: exercise.weight,
            reps: exercise.reps,
          ),
        ),
      ),
    ];
  }

  static List<SeriesEntry> flattenBlocks(List<TechniqueBlock> blocks) {
    final sorted = [...blocks]..sort((a, b) => a.order.compareTo(b.order));
    final flat = <SeriesEntry>[];
    var idx = 0;
    for (final block in sorted) {
      for (final entry in block.entries) {
        flat.add(entry.copyWith(index: idx++));
      }
    }
    return flat;
  }

  static WorkoutExercise withBlocks(
    WorkoutExercise exercise,
    List<TechniqueBlock> blocks,
  ) {
    final flat = flattenBlocks(blocks);
    return exercise.copyWith(
      blocks: blocks,
      entries: flat,
      series: flat.length,
    );
  }

  static WorkoutExercise normalize(WorkoutExercise exercise) {
    final blocks = ensureBlocks(exercise);
    return withBlocks(exercise, blocks);
  }

  static List<Map<String, dynamic>> blocksToDto(
    List<TechniqueBlock> blocks, {
    required int exerciseRir,
    required int exerciseRestTime,
  }) {
    final sorted = [...blocks]..sort((a, b) => a.order.compareTo(b.order));
    return sorted.map((block) {
      return {
        if (block.id != null) 'id': block.id,
        'type': block.type.apiValue,
        'order': block.order,
        if (block.label != null) 'label': block.label,
        if (block.restBetweenMiniSets != null)
          'restBetweenMiniSets': block.restBetweenMiniSets,
        'sets': block.entries
            .map(
              (e) => {
                'reps': parseReps(e.reps),
                'weight': parseWeight(e.weight),
                'label': e.backendLabel,
                if (exerciseRir > 0) 'rir': exerciseRir,
                if (exerciseRestTime > 0) 'restSeconds': exerciseRestTime,
                if (e.miniSetIndex != null) 'miniSetIndex': e.miniSetIndex,
                if (e.setType != null) 'setType': e.setType,
                'isDerived': e.isDerived,
              },
            )
            .toList(),
      };
    }).toList();
  }

  static int parseReps(String value) =>
      int.tryParse(RegExp(r'\d+').firstMatch(value)?.group(0) ?? '') ?? 0;

  static double parseWeight(String value) =>
      double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  static String suggestDropWeight(String source) {
    final parsed = parseWeight(source);
    if (parsed <= 0) return source;
    final dropped = (parsed * 0.7 * 2).round() / 2;
    return dropped % 1 == 0
        ? dropped.toInt().toString()
        : dropped.toStringAsFixed(1);
  }

  /// Converts a block to DROP. Multi-set blocks split: leading sets stay NORMAL,
  /// last primary set + derived drop form the DROP block.
  static List<TechniqueBlock> applyDropTechnique(
    List<TechniqueBlock> blocks,
    int blockIndex, {
    required String defaultWeight,
    required String defaultReps,
  }) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return blocks;

    final block = blocks[blockIndex];
    final nonDerived =
        block.entries.where((e) => !e.isDerived).toList(growable: false);

    if (nonDerived.isEmpty) return blocks;

    if (nonDerived.length == 1) {
      final primary = nonDerived.first;
      final next = [...blocks];
      next[blockIndex] = block.copyWith(
        type: TechniqueType.drop,
        entries: [
          primary,
          _derivedFromPrimary(primary, defaultWeight, defaultReps),
        ],
      );
      return next;
    }

    final leading = nonDerived.sublist(0, nonDerived.length - 1);
    final primary = nonDerived.last;
    final dropBlock = TechniqueBlock(
      type: TechniqueType.drop,
      order: block.order + 1,
      entries: [
        primary,
        _derivedFromPrimary(primary, defaultWeight, defaultReps),
      ],
    );

    final next = [...blocks];
    next[blockIndex] = block.copyWith(
      type: TechniqueType.normal,
      entries: leading,
    );
    next.insert(blockIndex + 1, dropBlock);
    return _reindexBlockOrders(next);
  }

  /// Human-readable reps pattern for cluster blocks, e.g. "2+2+2".
  static String clusterSummary(TechniqueBlock block) {
    if (block.entries.isEmpty) return '';
    return block.entries
        .where((e) => !e.isDerived)
        .map((e) => parseReps(e.reps))
        .join('+');
  }

  /// Subtitle under C1, C2… in the cluster shell UI.
  static String clusterStepSubtitle(
    int index,
    int count,
    int restSeconds,
  ) {
    if (count <= 0) return '';
    if (index == 0) return 'Primeira série';
    if (index == count - 1) return 'Última série';
    return 'Pausa ${restSeconds}s';
  }

  /// Badge text: `4+4+4 · 20s` (reps pattern + rest, no weight).
  static String clusterBadgeText(TechniqueBlock block) {
    final repsPart = clusterSummary(block);
    if (repsPart.isEmpty) return '';
    final rest =
        block.restBetweenMiniSets ?? defaultClusterRestSeconds;
    return '$repsPart · ${rest}s';
  }

  /// Header line: weight + reps pattern + rest for cluster execution.
  static String clusterExecutionSummary(TechniqueBlock block) {
    final repsPart = clusterSummary(block);
    if (repsPart.isEmpty) return '';
    final weight = block.entries
        .firstWhere(
          (e) => e.weight.isNotEmpty,
          orElse: () => block.entries.first,
        )
        .weight;
    final weightPart =
        weight.isNotEmpty && parseWeight(weight) > 0 ? '$weight · ' : '';
    final rest =
        block.restBetweenMiniSets ?? defaultClusterRestSeconds;
    return '$weightPart$repsPart · ${rest}s';
  }

  /// Truncates cluster to last completed mini-set; marks [terminatedEarly].
  static List<TechniqueBlock> terminateClusterEarly(
    List<TechniqueBlock> blocks,
    int blockIndex,
  ) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return blocks;

    final block = blocks[blockIndex];
    if (block.type != TechniqueType.cluster) return blocks;

    var lastDoneIndex = -1;
    for (var i = 0; i < block.entries.length; i++) {
      if (block.entries[i].done) lastDoneIndex = i;
    }

    if (lastDoneIndex < 0 && block.entries.isNotEmpty) {
      lastDoneIndex = 0;
    }

    final kept = lastDoneIndex < 0
        ? <SeriesEntry>[]
        : block.entries.sublist(0, lastDoneIndex + 1);

    final next = [...blocks];
    next[blockIndex] = block.copyWith(
      entries: kept,
      terminatedEarly: true,
    );
    return next;
  }

  /// Appends a derived drop row inside a CLUSTER block.
  static List<TechniqueBlock> appendClusterDrop(
    List<TechniqueBlock> blocks,
    int blockIndex, {
    required String defaultWeight,
    required String defaultReps,
  }) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return blocks;

    final block = blocks[blockIndex];
    if (block.type != TechniqueType.cluster || block.terminatedEarly) {
      return blocks;
    }

    final last = block.entries.isNotEmpty
        ? block.entries.last
        : SeriesEntry(index: 0, weight: defaultWeight, reps: defaultReps);

    final next = [...blocks];
    next[blockIndex] = block.copyWith(
      entries: [
        ...block.entries,
        _derivedFromPrimary(last, defaultWeight, defaultReps),
      ],
    );
    return next;
  }

  /// Converts a block to CLUSTER. Multi-set blocks split like DROP: leading sets
  /// stay NORMAL, last primary set becomes a cluster block with mini-sets.
  static List<TechniqueBlock> applyClusterTechnique(
    List<TechniqueBlock> blocks,
    int blockIndex, {
    required String defaultWeight,
    required String defaultReps,
    int miniSetCount = defaultClusterMiniSetCount,
    int repsPerMiniSet = defaultClusterRepsPerMiniSet,
    int restBetweenMiniSets = defaultClusterRestSeconds,
  }) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return blocks;

    final block = blocks[blockIndex];
    final nonDerived =
        block.entries.where((e) => !e.isDerived).toList(growable: false);

    if (nonDerived.isEmpty) return blocks;

    if (nonDerived.length == 1) {
      final primary = nonDerived.first;
      final next = [...blocks];
      next[blockIndex] = _clusterBlockFromPrimary(
        primary,
        block.order,
        defaultWeight: defaultWeight,
        defaultReps: defaultReps,
        miniSetCount: miniSetCount,
        repsPerMiniSet: repsPerMiniSet,
        restBetweenMiniSets: restBetweenMiniSets,
      );
      return next;
    }

    final leading = nonDerived.sublist(0, nonDerived.length - 1);
    final primary = nonDerived.last;
    final clusterBlock = _clusterBlockFromPrimary(
      primary,
      block.order + 1,
      defaultWeight: defaultWeight,
      defaultReps: defaultReps,
      miniSetCount: miniSetCount,
      repsPerMiniSet: repsPerMiniSet,
      restBetweenMiniSets: restBetweenMiniSets,
    );

    final next = [...blocks];
    next[blockIndex] = block.copyWith(
      type: TechniqueType.normal,
      entries: leading,
    );
    next.insert(blockIndex + 1, clusterBlock);
    return _reindexBlockOrders(next);
  }

  /// Appends a mini-set to an existing CLUSTER block (same weight/reps as last).
  static List<TechniqueBlock> appendClusterMiniSet(
    List<TechniqueBlock> blocks,
    int blockIndex, {
    required String defaultWeight,
    required String defaultReps,
  }) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return blocks;

    final block = blocks[blockIndex];
    if (block.type != TechniqueType.cluster) return blocks;

    final last = block.entries.isNotEmpty
        ? block.entries.last
        : SeriesEntry(index: 0, weight: defaultWeight, reps: defaultReps);

    final nextIndex = block.entries.length;
    final next = [...blocks];
    next[blockIndex] = block.copyWith(
      entries: [
        ...block.entries,
        SeriesEntry(
          index: last.index + 1,
          weight: last.weight.isNotEmpty ? last.weight : defaultWeight,
          reps: last.reps.isNotEmpty ? last.reps : defaultReps,
          miniSetIndex: nextIndex,
          setType: 'cluster',
        ),
      ],
    );
    return next;
  }

  static List<TechniqueBlock> appendDropSet(
    List<TechniqueBlock> blocks,
    int blockIndex, {
    required String defaultWeight,
    required String defaultReps,
  }) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return blocks;

    final block = blocks[blockIndex];
    final last = block.entries.isNotEmpty ? block.entries.last : null;
    final reference = last ?? SeriesEntry(index: 0, weight: defaultWeight, reps: defaultReps);

    final next = [...blocks];
    next[blockIndex] = block.copyWith(
      entries: [
        ...block.entries,
        _derivedFromPrimary(reference, defaultWeight, defaultReps),
      ],
    );
    return next;
  }

  static SeriesEntry _derivedFromPrimary(
    SeriesEntry primary,
    String defaultWeight,
    String defaultReps,
  ) {
    final weightSource =
        primary.weight.isNotEmpty ? primary.weight : defaultWeight;
    final repsSource = primary.reps.isNotEmpty ? primary.reps : defaultReps;
    return SeriesEntry(
      index: primary.index + 1,
      weight: suggestDropWeight(weightSource),
      reps: repsSource,
      isDerived: true,
    );
  }

  static TechniqueBlock _clusterBlockFromPrimary(
    SeriesEntry primary,
    int order, {
    required String defaultWeight,
    required String defaultReps,
    required int miniSetCount,
    required int repsPerMiniSet,
    required int restBetweenMiniSets,
  }) {
    final weight =
        primary.weight.isNotEmpty ? primary.weight : defaultWeight;
    final repsStr = repsPerMiniSet > 0
        ? repsPerMiniSet.toString()
        : (primary.reps.isNotEmpty ? primary.reps : defaultReps);

    return TechniqueBlock(
      type: TechniqueType.cluster,
      order: order,
      restBetweenMiniSets: restBetweenMiniSets,
      entries: List.generate(
        miniSetCount,
        (i) => SeriesEntry(
          index: primary.index + i,
          weight: weight,
          reps: repsStr,
          miniSetIndex: i,
          setType: 'cluster',
        ),
      ),
    );
  }

  /// Adiciona uma série de trabalho ao exercício (nunca dentro de cluster/drop).
  ///
  /// Se o último bloco for [TechniqueType.normal], acrescenta uma entrada nele.
  /// Se o último bloco for técnica (cluster, drop…), cria um bloco NORMAL novo no fim.
  static List<TechniqueBlock> appendExerciseSeries(
    List<TechniqueBlock> blocks, {
    required String weight,
    required String reps,
  }) {
    if (blocks.isEmpty) {
      return [
        TechniqueBlock(
          type: TechniqueType.normal,
          order: 0,
          entries: [SeriesEntry(index: 0, weight: weight, reps: reps)],
        ),
      ];
    }

    final last = blocks.last;
    if (last.type == TechniqueType.normal) {
      final next = [...blocks];
      next[next.length - 1] = last.copyWith(
        entries: [
          ...last.entries,
          SeriesEntry(
            index: last.entries.length,
            weight: weight,
            reps: reps,
          ),
        ],
      );
      return next;
    }

    return [
      ...blocks,
      TechniqueBlock(
        type: TechniqueType.normal,
        order: blocks.length,
        entries: [SeriesEntry(index: 0, weight: weight, reps: reps)],
      ),
    ];
  }

  static List<TechniqueBlock> _reindexBlockOrders(List<TechniqueBlock> blocks) {
    return blocks
        .asMap()
        .entries
        .map((e) => e.value.copyWith(order: e.key))
        .toList(growable: false);
  }
}
