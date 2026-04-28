import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/weight_unit.dart';


/// A single input row in the SeriesTable for editing series during workout.
/// Manages its own editing state with TextControllers for weight and reps entry.
class SeriesInputRow extends StatefulWidget {
  final SeriesEntry entry;
  final ValueChanged<SeriesEntry> onChanged;
  final ValueChanged<bool> onToggleDone;
  final WeightUnit weightUnit;
  final ValueNotifier<int>? activateWeightToken;
  final VoidCallback? onRepsDone;
  final bool isLastRow;

  const SeriesInputRow({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onToggleDone,
    this.weightUnit = WeightUnit.kg,
    this.activateWeightToken,
    this.onRepsDone,
    this.isLastRow = false,
  });

  @override
  State<SeriesInputRow> createState() => _SeriesInputRowState();
}

class _SeriesInputRowState extends State<SeriesInputRow> {
  late TextEditingController _weightController;
  late TextEditingController _repController;
  late bool _editingWeight;
  late bool _editingReps;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _repController = TextEditingController();
    _editingWeight = false;
    _editingReps = false;
    widget.activateWeightToken?.addListener(_onActivateWeight);
  }

  @override
  void dispose() {
    widget.activateWeightToken?.removeListener(_onActivateWeight);
    _weightController.dispose();
    _repController.dispose();
    super.dispose();
  }

  void _onActivateWeight() {
    setState(() {
      _editingWeight = true;
      _editingReps = false;
    });
  }

  void _updateEntry(SeriesEntry updated) {
    widget.onChanged(updated);
  }

  /// Propagates the weight on every keystroke so the parent always has the
  /// latest value — even if the user dismisses the keyboard without pressing Done.
  void _handleWeightChanged(String val) {
    if (val.isEmpty) return;
    _updateEntry(widget.entry.copyWith(weight: _cleanValue(val)));
  }

  void _handleWeightSubmitted(String val) {
    final weight = val.isEmpty ? widget.entry.weight : _cleanValue(val);
    _updateEntry(widget.entry.copyWith(weight: weight));
    setState(() {
      _editingWeight = false;
      _editingReps = true;
    });
  }

  /// Propagates reps on every keystroke.
  void _handleRepsChanged(String val) {
    if (val.isEmpty) return;
    _updateEntry(widget.entry.copyWith(reps: _cleanValue(val)));
  }

  void _handleRepsSubmitted(String val) {
    final reps = val.isEmpty ? widget.entry.reps : _cleanValue(val);
    _updateEntry(widget.entry.copyWith(reps: reps));
    setState(() => _editingReps = false);
    widget.onRepsDone?.call();
  }

  void _handleTypeChanged(int? type) {
    if (type == null) return;
    _updateEntry(widget.entry.copyWith(type: type));
  }

  void _handleDoneToggled(bool? value) {
    final newDone = value ?? false;
    _updateEntry(widget.entry.copyWith(done: newDone));
    widget.onToggleDone(newDone);
  }

  /// Extract a number (integer or decimal) from a value string.
  String _cleanValue(String value) {
    // Extract only numeric part (handles decimals like 1.5)
    final digits = RegExp(r'\d+\.?\d*').firstMatch(value);
    final result = digits?.group(0) ?? '0';
    return result;
  }

  /// Format value for display: show "-" if the value is "0", otherwise show the cleaned value.
  /// For placa: if it's an integer (like 1.0), display as integer (1)
  /// Never send '-' to backend — backend always receives numeric values from _cleanValue().
  String _displayValue(String value) {
    final clean = _cleanValue(value);
    if (clean == '0') {
      return '-';
    }

    // For placa unit, if value is integer (e.g., 1.0, 20.0), show without decimal
    final isPlaca = widget.weightUnit == WeightUnit.placa;
    if (isPlaca) {
      try {
        final parsed = double.parse(clean);
        if (parsed == parsed.toInt()) {
          return parsed.toInt().toString();
        }
      } catch (e) {
        // If parsing fails, just return clean value
      }
    }

    return clean;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(color: Colors.grey.shade50),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Série label + Tipo select (side by side) - matches flex: 3 from header
          Expanded(
            flex: 4,
            child: Row(
              spacing: 2,
              children: [
                Flexible(
                  flex: 2,
                  child: SizedBox(
                    height: 32,
                    child: DropdownButtonFormField<int>(
                      initialValue: widget.entry.type,
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Aquec.', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Prep.', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Trab', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Falha', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: _handleTypeChanged,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Série ${widget.entry.index + 1}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Weight field (click to edit) - matches flex: 1 from header
          Expanded(
            flex: 2,
            child: _editingWeight
                ? TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      // FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    onChanged: _handleWeightChanged,
                    onSubmitted: _handleWeightSubmitted,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: const OutlineInputBorder(),
                      hintText: _cleanValue(widget.entry.weight),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _editingWeight = true;
                        _editingReps = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _displayValue(widget.entry.weight),
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.weightUnit.label,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),

          // Reps field (click to edit) - matches flex: 1 from header
          Expanded(
            flex: 1,
            child: _editingReps
                ? TextField(
                    controller: _repController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: widget.isLastRow
                        ? TextInputAction.done
                        : TextInputAction.next,
                    autofocus: true,
                    onChanged: _handleRepsChanged,
                    onSubmitted: _handleRepsSubmitted,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: const OutlineInputBorder(),
                      hintText: widget.entry.reps,
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _editingReps = true;
                        _editingWeight = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        _displayValue(widget.entry.reps),
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),

          // Done checkbox - matches SizedBox(width: 48) from header
          SizedBox(
            width: 48,
            child: Checkbox(
              value: widget.entry.done,
              onChanged: _handleDoneToggled,
            ),
          ),
        ],
      ),
    );
  }
}
