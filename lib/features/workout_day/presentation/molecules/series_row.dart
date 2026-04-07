import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'series_entry.dart';

/// A single row in the SeriesTable, managing its own editing state and controllers.
class SeriesRow extends StatefulWidget {
  final SeriesEntry entry;
  final ValueChanged<SeriesEntry> onChanged;
  final ValueChanged<bool> onToggleDone;
  final String weightUnit;
  final ValueNotifier<int>? activateWeightToken;
  final VoidCallback? onRepsDone;
  final bool isLastRow;

  const SeriesRow({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onToggleDone,
    this.weightUnit = 'kg',
    this.activateWeightToken,
    this.onRepsDone,
    this.isLastRow = false,
  });

  @override
  State<SeriesRow> createState() => _SeriesRowState();
}

class _SeriesRowState extends State<SeriesRow> {
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
    _weightController.clear();
    setState(() {
      _editingWeight = true;
      _editingReps = false;
    });
  }

  void _updateEntry(SeriesEntry updated) {
    widget.onChanged(updated);
  }

  void _handleWeightSubmitted(String val) {
    _updateEntry(widget.entry.copyWith(weight: _cleanValue(val)));
    setState(() {
      _editingWeight = false;
      _editingReps = true; // avança automaticamente para reps
    });
  }

  void _handleRepsSubmitted(String val) {
    _updateEntry(widget.entry.copyWith(reps: _cleanValue(val)));
    setState(() => _editingReps = false);
    widget.onRepsDone?.call(); // sinaliza para próxima série
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

  /// Extract only the first sequence of digits from a value (ignores ranges like "-")
  String _cleanValue(String value) {
    final digits = RegExp(r'\d+').firstMatch(value);
    return digits?.group(0) ?? '0';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            flex: 1,
            child: _editingWeight
                ? TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    autofocus: true,
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
                      _weightController.clear();
                      setState(() => _editingWeight = true);
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
                            _cleanValue(widget.entry.weight),
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.weightUnit,
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
                      _repController.clear();
                      setState(() => _editingReps = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        _cleanValue(widget.entry.reps),
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
