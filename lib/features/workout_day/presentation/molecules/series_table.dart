import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'series_input_row.dart';

/// A table displaying workout series with type, weight, reps, and completion status.
/// Manages a list of SeriesEntry models and renders them as individual SeriesRow widgets.
class SeriesTable extends StatefulWidget {
  final int count;
  final String weight;
  final String reps;
  final void Function(int index, bool done)? onToggleDone;
  final String weightUnit;
  /// Called with the full updated entries list whenever any row changes.
  final void Function(List<SeriesEntry> entries)? onEntriesChanged;
  /// Optional pre-populated entries (e.g. loaded from a previous workout).
  final List<SeriesEntry>? initialEntries;

  const SeriesTable({
    super.key,
    required this.count,
    required this.weight,
    required this.reps,
    this.onToggleDone,
    this.weightUnit = 'kg',
    this.onEntriesChanged,
    this.initialEntries,
  });

  @override
  State<SeriesTable> createState() => _SeriesTableState();
}

class _SeriesTableState extends State<SeriesTable> {
  late List<SeriesEntry> _entries;
  late List<ValueNotifier<int>> _activateWeightTokens;

  @override
  void initState() {
    super.initState();
    _initializeEntries();
  }

  void _initializeEntries() {
    final initial = widget.initialEntries;
    if (initial != null && initial.isNotEmpty) {
      // Use provided entries; append new default rows if count grew.
      _entries = List<SeriesEntry>.from(initial);
      if (_entries.length < widget.count) {
        for (var i = _entries.length; i < widget.count; i++) {
          _entries.add(SeriesEntry(
            index: i,
            weight: widget.weight,
            reps: widget.reps,
          ));
        }
      } else if (_entries.length > widget.count) {
        _entries = _entries.sublist(0, widget.count);
      }
    } else {
      _entries = List.generate(
        widget.count,
        (i) => SeriesEntry(index: i, weight: widget.weight, reps: widget.reps),
      );
    }
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
      // Preserve existing entries and extend/trim based on new count.
      final previous = List<SeriesEntry>.from(_entries);
      _activateWeightTokens = List.generate(widget.count, (_) => ValueNotifier(0));
      if (widget.count > previous.length) {
        _entries = [
          ...previous,
          for (var i = previous.length; i < widget.count; i++)
            SeriesEntry(index: i, weight: widget.weight, reps: widget.reps),
        ];
      } else {
        _entries = previous.sublist(0, widget.count);
      }
    }
  }

  void _handleEntryChanged(int index, SeriesEntry updated) {
    setState(() {
      _entries[index] = updated;
    });
    widget.onEntriesChanged?.call(List.unmodifiable(_entries));
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
                  'PESO (${widget.weightUnit.toUpperCase()})',
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
        ..._entries.asMap().entries.map((entry) {
          final index = entry.key;
          final seriesEntry = entry.value;
          final isLast = index == _entries.length - 1;
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
        }),

        // TODO: When per-series data persistence is needed, wire onToggleDone
        // callback to the provider/backend and store individual series state.
      ],
    );
  }
}
