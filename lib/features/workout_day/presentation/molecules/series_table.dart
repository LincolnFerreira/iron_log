import 'package:flutter/material.dart';
import 'series_entry.dart';
import 'series_row.dart';

/// A table displaying workout series with type, weight, reps, and completion status.
/// Manages a list of SeriesEntry models and renders them as individual SeriesRow widgets.
class SeriesTable extends StatefulWidget {
  final int count;
  final String weight;
  final String reps;
  final void Function(int index, bool done)? onToggleDone;

  const SeriesTable({
    super.key,
    required this.count,
    required this.weight,
    required this.reps,
    this.onToggleDone,
  });

  @override
  State<SeriesTable> createState() => _SeriesTableState();
}

class _SeriesTableState extends State<SeriesTable> {
  late List<SeriesEntry> _entries;

  @override
  void initState() {
    super.initState();
    _initializeEntries();
  }

  void _initializeEntries() {
    _entries = List.generate(
      widget.count,
      (i) => SeriesEntry(index: i, weight: widget.weight, reps: widget.reps),
    );
  }

  @override
  void didUpdateWidget(covariant SeriesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _initializeEntries();
    }
  }

  void _handleEntryChanged(int index, SeriesEntry updated) {
    setState(() {
      _entries[index] = updated;
    });
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
                  'PESO (KG)',
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
          return SeriesRow(
            key: ValueKey(index),
            entry: seriesEntry,
            onChanged: (updated) => _handleEntryChanged(index, updated),
            onToggleDone: (done) => _handleToggleDone(index, done),
          );
        }),

        // TODO: When per-series data persistence is needed, wire onToggleDone
        // callback to the provider/backend and store individual series state.
      ],
    );
  }
}
