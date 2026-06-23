import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/weight_unit.dart';
import 'package:iron_log/features/workout_day/domain/mappers/technique_block_mapper.dart';
import 'package:iron_log/features/workout_day/presentation/exercise_card_styles.dart';
import 'package:iron_log/features/workout_day/presentation/series_visual_style.dart';
import 'package:iron_log/features/workout_day/presentation/workout_test_keys.dart';
import 'series_input_row.dart';

/// Mini-tabela de séries com colunas alinhadas: tipo, peso, reps, feito.
class SeriesTable extends StatefulWidget {
  final int count;
  final String weight;
  final String reps;
  final List<SeriesEntry> entries;
  final void Function(int index, bool done)? onToggleDone;
  final WeightUnit weightUnit;
  final void Function(List<SeriesEntry> entries)? onEntriesChanged;
  final ValueChanged<int>? onSeriesRowInteract;
  final bool showColumnHeader;
  final bool hideTypeForDerived;
  final bool hideTypeForCluster;
  final int? clusterRestSeconds;
  final int seriesKeyOffset;
  final SeriesVisualStyle visualStyle;
  final bool showTerminateCluster;
  final bool clusterTerminatedEarly;
  final VoidCallback? onTerminateCluster;

  const SeriesTable({
    super.key,
    required this.count,
    required this.weight,
    required this.reps,
    required this.entries,
    this.onToggleDone,
    this.weightUnit = WeightUnit.kg,
    this.onEntriesChanged,
    this.onSeriesRowInteract,
    this.showColumnHeader = true,
    this.hideTypeForDerived = false,
    this.hideTypeForCluster = false,
    this.clusterRestSeconds,
    this.seriesKeyOffset = 0,
    this.visualStyle = SeriesVisualStyle.standard,
    this.showTerminateCluster = false,
    this.clusterTerminatedEarly = false,
    this.onTerminateCluster,
  });

  @override
  State<SeriesTable> createState() => _SeriesTableState();
}

class _SeriesTableState extends State<SeriesTable> {
  late List<ValueNotifier<int>> _activateWeightTokens;

  bool get _compact => widget.visualStyle == SeriesVisualStyle.compactExecution;

  bool get _isClusterMiniSets =>
      widget.hideTypeForCluster && widget.clusterRestSeconds != null;

  @override
  void initState() {
    super.initState();
    _activateWeightTokens = List.generate(
      widget.count,
      (_) => ValueNotifier(0),
    );
  }

  @override
  void dispose() {
    for (final token in _activateWeightTokens) {
      token.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SeriesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      final grew = widget.count > oldWidget.count;
      for (final token in _activateWeightTokens) {
        token.dispose();
      }
      _activateWeightTokens = List.generate(
        widget.count,
        (_) => ValueNotifier(0),
      );
      if (grew && widget.count > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _activateWeightTokens[widget.count - 1].value++;
        });
      }
    }
  }

  List<SeriesEntry> _resolvedEntries() {
    final result = List<SeriesEntry>.from(widget.entries);
    while (result.length < widget.count) {
      result.add(
        SeriesEntry(
          index: result.length,
          weight: widget.weight,
          reps: widget.reps,
        ),
      );
    }
    if (result.length > widget.count) return result.sublist(0, widget.count);
    return result;
  }

  void _handleEntryChanged(int index, SeriesEntry updated) {
    final result = List<SeriesEntry>.from(widget.entries);
    while (result.length <= index) {
      result.add(
        SeriesEntry(
          index: result.length,
          weight: widget.weight,
          reps: widget.reps,
        ),
      );
    }
    result[index] = updated;
    widget.onEntriesChanged?.call(List<SeriesEntry>.unmodifiable(result));
  }

  void _handleToggleDone(int index, bool done) {
    widget.onToggleDone?.call(index, done);
  }

  String? _seriesLabel(SeriesEntry entry, int rowIndex) {
    if (entry.isDerived) return '↓';
    if (widget.hideTypeForCluster) {
      final clusterIndex = entry.miniSetIndex ?? rowIndex;
      return 'C${clusterIndex + 1}';
    }
    return null;
  }

  bool _showTypeColumn(SeriesEntry entry) {
    if (widget.hideTypeForCluster) return false;
    if (widget.hideTypeForDerived && entry.isDerived) return false;
    return true;
  }

  String? _clusterStepSubtitle(int index, int count) {
    if (!_isClusterMiniSets) return null;
    final rest =
        widget.clusterRestSeconds ??
        TechniqueBlockMapper.defaultClusterRestSeconds;
    return TechniqueBlockMapper.clusterStepSubtitle(index, count, rest);
  }

  Widget _buildTerminateClusterButton() {
    if (!widget.showTerminateCluster || widget.clusterTerminatedEarly) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          key: WorkoutTestKeys.terminateCluster,
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onTerminateCluster?.call();
          },
          icon: const Icon(Icons.stop_circle_outlined, size: 16),
          label: const Text('Encerrar cluster'),
          style: TextButton.styleFrom(
            foregroundColor: ExerciseCardStyles.labelMuted,
            padding: const EdgeInsets.symmetric(vertical: 8),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableBody() {
    final entries = _resolvedEntries();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showColumnHeader)
          Padding(
            padding: EdgeInsets.only(
              bottom: 4,
              left: _compact ? 8 : 0,
              right: _compact ? 8 : 0,
            ),
            child: Row(
              children: [
                SizedBox(width: ExerciseCardStyles.seriesLabelWidth),
                const SizedBox(width: ExerciseCardStyles.columnGap),
                if (!widget.hideTypeForCluster) ...[
                  const Expanded(
                    flex: 3,
                    child: Text('TIPO', style: ExerciseCardStyles.headerStyle),
                  ),
                  const SizedBox(width: ExerciseCardStyles.columnGap),
                ],
                Expanded(
                  child: Text(
                    'PESO (${widget.weightUnit.label.toUpperCase()})',
                    style: ExerciseCardStyles.headerStyle,
                  ),
                ),
                const SizedBox(width: ExerciseCardStyles.columnGap),
                const Expanded(
                  child: Text('REPS', style: ExerciseCardStyles.headerStyle),
                ),
                const SizedBox(width: ExerciseCardStyles.columnGap),
                const SizedBox(
                  width: ExerciseCardStyles.doneColumnWidth,
                  child: Center(
                    child: Text('FEITO', style: ExerciseCardStyles.headerStyle),
                  ),
                ),
              ],
            ),
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Column(
            children: entries.asMap().entries.expand((entry) {
              final index = entry.key;
              final seriesEntry = entry.value;
              final isLast = index == entries.length - 1;
              final row = SeriesInputRow(
                key: ValueKey(
                  '${seriesEntry.index}_${seriesEntry.isDerived}_${seriesEntry.miniSetIndex}',
                ),
                entry: seriesEntry,
                isFirstRow: index == 0,
                isLastRow: isLast,
                onChanged: (updated) => _handleEntryChanged(index, updated),
                onToggleDone: (done) => _handleToggleDone(index, done),
                weightUnit: widget.weightUnit,
                activateWeightToken: _activateWeightTokens[index],
                onInteract: () => widget.onSeriesRowInteract?.call(index),
                onRepsDone: isLast
                    ? null
                    : () => _activateWeightTokens[index + 1].value++,
                seriesLabelOverride: _seriesLabel(seriesEntry, index),
                stepSubtitle: _clusterStepSubtitle(index, entries.length),
                showTypeColumn: _showTypeColumn(seriesEntry),
                seriesKeyIndex: widget.seriesKeyOffset + index,
                visualStyle: widget.visualStyle,
                isClusterMiniSet: widget.hideTypeForCluster,
              );

              return [row];
            }).toList(),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _compact ? 8 : 0),
          child: _buildTerminateClusterButton(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) {
      return const SizedBox.shrink();
    }

    final body = _buildTableBody();

    if (!_compact) return body;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: ExerciseCardStyles.techniqueExecutionTableDecoration(),
      child: body,
    );
  }
}
