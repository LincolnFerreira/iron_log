import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_block.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_type.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/mappers/technique_block_mapper.dart';

WorkoutExercise _sampleExercise({
  List<SeriesEntry> entries = const [],
  List<TechniqueBlock> blocks = const [],
}) {
  return WorkoutExercise(
    id: 'ex1',
    name: 'Supino',
    tag: ExerciseTag.multi,
    muscles: 'Peito',
    variation: 'Traditional',
    series: entries.length,
    reps: '8',
    weight: '40',
    rir: 2,
    restTime: 120,
    entries: entries,
    blocks: blocks,
  );
}

void main() {
  group('TechniqueBlockMapper', () {
    test('synthesizes NORMAL block from flat entries', () {
      final exercise = _sampleExercise(
        entries: [
          SeriesEntry(index: 0, weight: '40', reps: '8'),
          SeriesEntry(index: 1, weight: '40', reps: '8'),
        ],
      );

      final blocks = TechniqueBlockMapper.ensureBlocks(exercise);
      expect(blocks, hasLength(1));
      expect(blocks.first.type, TechniqueType.normal);
      expect(blocks.first.entries, hasLength(2));
    });

    test('blocksToDto emits DROP with derived set', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.drop,
          order: 0,
          entries: [
            SeriesEntry(index: 0, weight: '34', reps: '8'),
            SeriesEntry(
              index: 1,
              weight: '24',
              reps: '12',
              isDerived: true,
            ),
          ],
        ),
      ];

      final dto = TechniqueBlockMapper.blocksToDto(
        blocks,
        exerciseRir: 2,
        exerciseRestTime: 120,
      );

      expect(dto, hasLength(1));
      expect(dto.first['type'], 'DROP');
      expect(dto.first['sets'], hasLength(2));
      expect(dto.first['sets'][1]['isDerived'], isTrue);
    });

    test('flattenBlocks preserves order across blocks', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.warmup,
          order: 0,
          entries: [SeriesEntry(index: 0, weight: '20', reps: '12')],
        ),
        TechniqueBlock(
          type: TechniqueType.normal,
          order: 1,
          entries: [SeriesEntry(index: 0, weight: '40', reps: '8')],
        ),
      ];

      final flat = TechniqueBlockMapper.flattenBlocks(blocks);
      expect(flat, hasLength(2));
      expect(flat[0].index, 0);
      expect(flat[1].index, 1);
    });

    test('applyDropTechnique on single set adds derived row', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.normal,
          order: 0,
          entries: [SeriesEntry(index: 0, weight: '34', reps: '8')],
        ),
      ];

      final result = TechniqueBlockMapper.applyDropTechnique(
        blocks,
        0,
        defaultWeight: '34',
        defaultReps: '8',
      );

      expect(result, hasLength(1));
      expect(result.first.type, TechniqueType.drop);
      expect(result.first.entries, hasLength(2));
      expect(result.first.entries.last.isDerived, isTrue);
    });

    test('applyDropTechnique on multi-set splits NORMAL + DROP', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.normal,
          order: 0,
          entries: [
            SeriesEntry(index: 0, weight: '20', reps: '12'),
            SeriesEntry(index: 1, weight: '34', reps: '8'),
          ],
        ),
      ];

      final result = TechniqueBlockMapper.applyDropTechnique(
        blocks,
        0,
        defaultWeight: '34',
        defaultReps: '8',
      );

      expect(result, hasLength(2));
      expect(result[0].type, TechniqueType.normal);
      expect(result[0].entries, hasLength(1));
      expect(result[1].type, TechniqueType.drop);
      expect(result[1].entries, hasLength(2));
    });

    test('applyClusterTechnique creates mini-sets with metadata', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.normal,
          order: 0,
          entries: [SeriesEntry(index: 0, weight: '34', reps: '8')],
        ),
      ];

      final result = TechniqueBlockMapper.applyClusterTechnique(
        blocks,
        0,
        defaultWeight: '34',
        defaultReps: '8',
        miniSetCount: 3,
        repsPerMiniSet: 2,
        restBetweenMiniSets: 20,
      );

      expect(result, hasLength(1));
      expect(result.first.type, TechniqueType.cluster);
      expect(result.first.restBetweenMiniSets, 20);
      expect(result.first.entries, hasLength(3));
      expect(result.first.entries.first.miniSetIndex, 0);
      expect(result.first.entries.first.setType, 'cluster');
      expect(TechniqueBlockMapper.clusterSummary(result.first), '2+2+2');
    });

    test('blocksToDto emits CLUSTER with miniSetIndex', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.cluster,
          order: 0,
          restBetweenMiniSets: 20,
          entries: [
            SeriesEntry(
              index: 0,
              weight: '34',
              reps: '2',
              miniSetIndex: 0,
              setType: 'cluster',
            ),
            SeriesEntry(
              index: 1,
              weight: '34',
              reps: '2',
              miniSetIndex: 1,
              setType: 'cluster',
            ),
          ],
        ),
      ];

      final dto = TechniqueBlockMapper.blocksToDto(
        blocks,
        exerciseRir: 0,
        exerciseRestTime: 120,
      );

      expect(dto.first['type'], 'CLUSTER');
      expect(dto.first['restBetweenMiniSets'], 20);
      expect(dto.first['sets'][0]['miniSetIndex'], 0);
      expect(dto.first['sets'][1]['miniSetIndex'], 1);
    });

    test('appendClusterMiniSet adds mini-set with incremented index', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.cluster,
          order: 0,
          restBetweenMiniSets: 20,
          entries: [
            SeriesEntry(
              index: 0,
              weight: '34',
              reps: '2',
              miniSetIndex: 0,
              setType: 'cluster',
            ),
          ],
        ),
      ];

      final result = TechniqueBlockMapper.appendClusterMiniSet(
        blocks,
        0,
        defaultWeight: '34',
        defaultReps: '2',
      );

      expect(result.first.entries, hasLength(2));
      expect(result.first.entries.last.miniSetIndex, 1);
      expect(result.first.entries.last.weight, '34');
    });

    test('terminateClusterEarly keeps done mini-sets and marks flag', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.cluster,
          order: 0,
          restBetweenMiniSets: 20,
          entries: [
            SeriesEntry(
              index: 0,
              weight: '40',
              reps: '2',
              done: true,
              miniSetIndex: 0,
              setType: 'cluster',
            ),
            SeriesEntry(
              index: 1,
              weight: '40',
              reps: '2',
              done: true,
              miniSetIndex: 1,
              setType: 'cluster',
            ),
            SeriesEntry(
              index: 2,
              weight: '40',
              reps: '2',
              miniSetIndex: 2,
              setType: 'cluster',
            ),
          ],
        ),
      ];

      final result = TechniqueBlockMapper.terminateClusterEarly(blocks, 0);

      expect(result.first.terminatedEarly, isTrue);
      expect(result.first.entries, hasLength(2));
      expect(TechniqueBlockMapper.clusterSummary(result.first), '2+2');
    });

    test('appendClusterDrop adds derived row with lighter weight', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.cluster,
          order: 0,
          entries: [
            SeriesEntry(
              index: 0,
              weight: '40',
              reps: '2',
              miniSetIndex: 0,
              setType: 'cluster',
            ),
          ],
        ),
      ];

      final result = TechniqueBlockMapper.appendClusterDrop(
        blocks,
        0,
        defaultWeight: '40',
        defaultReps: '2',
      );

      expect(result.first.entries, hasLength(2));
      expect(result.first.entries.last.isDerived, isTrue);
      expect(
        TechniqueBlockMapper.parseWeight(result.first.entries.last.weight),
        lessThan(40),
      );
    });

    test('clusterExecutionSummary includes weight and rest', () {
      final block = TechniqueBlock(
        type: TechniqueType.cluster,
        order: 0,
        restBetweenMiniSets: 20,
        entries: [
          SeriesEntry(index: 0, weight: '40', reps: '2', miniSetIndex: 0),
          SeriesEntry(index: 1, weight: '40', reps: '2', miniSetIndex: 1),
        ],
      );

      expect(
        TechniqueBlockMapper.clusterExecutionSummary(block),
        '40 · 2+2 · 20s',
      );
    });

    test('clusterStepSubtitle labels first, pause and last', () {
      expect(
        TechniqueBlockMapper.clusterStepSubtitle(0, 3, 20),
        'Primeira série',
      );
      expect(
        TechniqueBlockMapper.clusterStepSubtitle(1, 3, 20),
        'Pausa 20s',
      );
      expect(
        TechniqueBlockMapper.clusterStepSubtitle(2, 3, 20),
        'Última série',
      );
    });

    test('appendExerciseSeries after cluster adds new normal block at end', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.normal,
          order: 0,
          entries: [
            SeriesEntry(index: 0, weight: '40', reps: '8'),
            SeriesEntry(index: 1, weight: '40', reps: '8'),
          ],
        ),
        TechniqueBlock(
          type: TechniqueType.cluster,
          order: 1,
          entries: [
            SeriesEntry(index: 0, weight: '40', reps: '4', miniSetIndex: 0),
            SeriesEntry(index: 1, weight: '40', reps: '4', miniSetIndex: 1),
          ],
        ),
      ];

      final result = TechniqueBlockMapper.appendExerciseSeries(
        blocks,
        weight: '40',
        reps: '8',
      );

      expect(result, hasLength(3));
      expect(result[0].entries, hasLength(2));
      expect(result[1].type, TechniqueType.cluster);
      expect(result[1].entries, hasLength(2));
      expect(result[2].type, TechniqueType.normal);
      expect(result[2].entries, hasLength(1));
      expect(result[2].entries.first.reps, '8');
    });

    test('appendExerciseSeries extends last block when it is normal', () {
      final blocks = [
        TechniqueBlock(
          type: TechniqueType.normal,
          order: 0,
          entries: [SeriesEntry(index: 0, weight: '40', reps: '8')],
        ),
      ];

      final result = TechniqueBlockMapper.appendExerciseSeries(
        blocks,
        weight: '40',
        reps: '10',
      );

      expect(result, hasLength(1));
      expect(result.first.entries, hasLength(2));
      expect(result.first.entries.last.reps, '10');
    });

    test('clusterBadgeText is reps pattern and rest without weight', () {
      final block = TechniqueBlock(
        type: TechniqueType.cluster,
        order: 0,
        restBetweenMiniSets: 20,
        entries: [
          SeriesEntry(index: 0, weight: '40', reps: '4', miniSetIndex: 0),
          SeriesEntry(index: 1, weight: '40', reps: '4', miniSetIndex: 1),
        ],
      );

      expect(
        TechniqueBlockMapper.clusterBadgeText(block),
        '4+4 · 20s',
      );
    });
  });
}
