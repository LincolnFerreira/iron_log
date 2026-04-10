import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/weight_unit.dart';
import 'series_input_row.dart';

/// A table displaying workout series with type, weight, reps, and completion status.
/// Controlled component — the caller owns the entries list via [onEntriesChanged].
class SeriesTable extends StatefulWidget {
  final int count;
  final String weight; // default weight for auto-generated rows
  final String reps; // default reps for auto-generated rows

  /// The authoritative list of series entries maintained by the parent.
  final List<SeriesEntry> entries;

  final void Function(int index, bool done)? onToggleDone;
  final WeightUnit weightUnit;

  /// Called with the full updated entries list whenever any row changes.
  final void Function(List<SeriesEntry> entries)? onEntriesChanged;

  const SeriesTable({
    super.key,
    required this.count,
    required this.weight,
    required this.reps,
    required this.entries,
    this.onToggleDone,
    this.weightUnit = WeightUnit.kg,
    this.onEntriesChanged,
  });

  @override
  State<SeriesTable> createState() => _SeriesTableState();
}

class _SeriesTableState extends State<SeriesTable> {
  // Only UI state lives here — no data copies.
  late List<ValueNotifier<int>> _activateWeightTokens;

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
      for (final token in _activateWeightTokens) {
        token.dispose();
      }
      _activateWeightTokens = List.generate(
        widget.count,
        (_) => ValueNotifier(0),
      );
    }
  }

  /// Returns the effective display list: fills to [count] with defaults,
  /// or trims if the parent passed more than [count] entries.
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

    print('  resolved result.length: ${result.length}');
    if (result.isNotEmpty) {
      print('  ✓ first resolved entry.weight: "${result[0].weight}"');
    }
    return result;
  }

  void _handleEntryChanged(int index, SeriesEntry updated) {
    // Merge only the changed index into the parent-owned list.
    // Never call _resolvedEntries() here — that would inject defaults into
    // entries the user hasn't touched yet, corrupting the payload.
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

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'TIPO',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PESO (${widget.weightUnit.displayLabel.toUpperCase()})',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'REPS',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 48,
                child: Center(
                  child: Text(
                    'FEITO',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Series rows
        ...() {
          final entries = _resolvedEntries();
          return entries.asMap().entries.map((entry) {
            final index = entry.key;
            final seriesEntry = entry.value;
            final isLast = index == entries.length - 1;
            return SeriesInputRow(
              key: ValueKey(index),
              entry: seriesEntry,
              onChanged: (updated) => _handleEntryChanged(index, updated),
              onToggleDone: (done) => _handleToggleDone(index, done),
              weightUnit: widget.weightUnit,
              activateWeightToken: _activateWeightTokens[index],
              isLastRow: isLast,
              onRepsDone: isLast
                  ? null
                  : () => _activateWeightTokens[index + 1].value++,
            );
          }).toList();
        }(),

        // TODO: When per-series data persistence is needed, wire onToggleDone
        // callback to the provider/backend and store individual series state.
      ],
    );
  }
}
