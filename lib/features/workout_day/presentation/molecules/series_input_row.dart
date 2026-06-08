import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/weight_unit.dart';
import 'package:iron_log/features/workout_day/presentation/exercise_card_styles.dart';
import 'package:iron_log/features/workout_day/presentation/series_visual_style.dart';
import 'package:iron_log/features/workout_day/presentation/workout_test_keys.dart';

/// Uma linha da mini-tabela de séries (tipo, peso, reps, feito).
class SeriesInputRow extends StatefulWidget {
  final SeriesEntry entry;
  final ValueChanged<SeriesEntry> onChanged;
  final ValueChanged<bool> onToggleDone;
  final WeightUnit weightUnit;
  final ValueNotifier<int>? activateWeightToken;
  final VoidCallback? onRepsDone;
  final bool isFirstRow;
  final bool isLastRow;
  final VoidCallback? onInteract;
  final String? seriesLabelOverride;
  final String? stepSubtitle;
  final bool showTypeColumn;
  final int? seriesKeyIndex;
  final SeriesVisualStyle visualStyle;
  /// True quando a linha é um mini-set filho de um cluster.
  final bool isClusterMiniSet;

  const SeriesInputRow({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onToggleDone,
    this.weightUnit = WeightUnit.kg,
    this.activateWeightToken,
    this.onRepsDone,
    this.isFirstRow = true,
    this.isLastRow = false,
    this.onInteract,
    this.seriesLabelOverride,
    this.stepSubtitle,
    this.showTypeColumn = true,
    this.seriesKeyIndex,
    this.visualStyle = SeriesVisualStyle.standard,
    this.isClusterMiniSet = false,
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
    widget.onInteract?.call();
    setState(() {
      _editingWeight = true;
      _editingReps = false;
    });
  }

  void _updateEntry(SeriesEntry updated) {
    widget.onChanged(updated);
    widget.onInteract?.call();
  }

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

  String _cleanValue(String value) {
    final digits = RegExp(r'\d+\.?\d*').firstMatch(value);
    return digits?.group(0) ?? '0';
  }

  String _displayValue(String value) {
    final clean = _cleanValue(value);
    if (clean == '0') return '-';

    if (widget.weightUnit == WeightUnit.placa) {
      try {
        final parsed = double.parse(clean);
        if (parsed == parsed.toInt()) {
          return parsed.toInt().toString();
        }
      } catch (_) {}
    }

    return clean;
  }

  bool get _compact => widget.visualStyle == SeriesVisualStyle.compactExecution;

  double get _fieldHeight => _compact
      ? ExerciseCardStyles.compactFieldHeight
      : ExerciseCardStyles.fieldHeight;

  TextStyle get _fieldTextStyle => _compact
      ? ExerciseCardStyles.compactFieldTextStyle
      : ExerciseCardStyles.fieldTextStyle;

  TextStyle get _unitHintStyle => _compact
      ? ExerciseCardStyles.compactUnitHintStyle
      : ExerciseCardStyles.unitHintStyle;

  Widget _fieldShell({required Widget child, VoidCallback? onTap}) {
    final box = Container(
      height: _fieldHeight,
      alignment: Alignment.center,
      decoration: ExerciseCardStyles.fieldBoxDecoration(compact: _compact),
      child: child,
    );

    if (onTap == null) return box;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: box,
    );
  }

  Widget _buildTypeField() {
    const itemStyle = ExerciseCardStyles.fieldTextStyle;

    return SizedBox(
      height: ExerciseCardStyles.fieldHeight,
      child: DropdownButtonFormField<int>(
        initialValue: widget.entry.type,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        iconSize: 20,
        style: itemStyle,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(ExerciseCardStyles.fieldRadius),
        menuMaxHeight: 240,
        items: const [
          DropdownMenuItem(value: 0, child: Text('Aquec.', style: itemStyle)),
          DropdownMenuItem(value: 1, child: Text('Prep.', style: itemStyle)),
          DropdownMenuItem(value: 2, child: Text('Trab', style: itemStyle)),
          DropdownMenuItem(value: 3, child: Text('Falha', style: itemStyle)),
        ],
        onChanged: _handleTypeChanged,
        decoration: ExerciseCardStyles.dropdownDecoration(),
      ),
    );
  }

  Widget _buildWeightField() {
    final fieldKey = widget.seriesKeyIndex != null
        ? WorkoutTestKeys.seriesWeight(widget.seriesKeyIndex!)
        : null;

    if (_editingWeight) {
      return SizedBox(
        height: _fieldHeight,
        child: TextField(
          key: fieldKey,
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          autofocus: true,
          style: _fieldTextStyle,
          onChanged: _handleWeightChanged,
          onSubmitted: _handleWeightSubmitted,
          decoration: ExerciseCardStyles.fieldDecoration(
            hintText: _cleanValue(widget.entry.weight),
            compact: _compact,
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: fieldKey,
      child: _fieldShell(
        onTap: () {
          widget.onInteract?.call();
          setState(() {
            _editingWeight = true;
            _editingReps = false;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_displayValue(widget.entry.weight), style: _fieldTextStyle),
            const SizedBox(width: 4),
            Text(widget.weightUnit.label, style: _unitHintStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildRepsField() {
    final fieldKey = widget.seriesKeyIndex != null
        ? WorkoutTestKeys.seriesReps(widget.seriesKeyIndex!)
        : null;

    if (_editingReps) {
      return SizedBox(
        height: _fieldHeight,
        child: TextField(
          key: fieldKey,
          controller: _repController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: widget.isLastRow
              ? TextInputAction.done
              : TextInputAction.next,
          autofocus: true,
          style: _fieldTextStyle,
          onChanged: _handleRepsChanged,
          onSubmitted: _handleRepsSubmitted,
          decoration: ExerciseCardStyles.fieldDecoration(
            hintText: widget.entry.reps,
            compact: _compact,
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: fieldKey,
      child: _fieldShell(
        onTap: () {
          widget.onInteract?.call();
          setState(() {
            _editingReps = true;
            _editingWeight = false;
          });
        },
        child: Text(_displayValue(widget.entry.reps), style: _fieldTextStyle),
      ),
    );
  }

  Widget _buildDoneCheckbox() {
    final doneKey = widget.seriesKeyIndex != null
        ? WorkoutTestKeys.seriesDone(widget.seriesKeyIndex!)
        : null;

    final checkboxSize = _compact
        ? ExerciseCardStyles.compactCheckboxSize
        : ExerciseCardStyles.checkboxSize;

    return Theme(
      data: ExerciseCardStyles.checkboxTheme(context),
      child: SizedBox(
        width: checkboxSize,
        height: checkboxSize,
        child: Checkbox(
          key: doneKey,
          value: widget.entry.done,
          onChanged: _handleDoneToggled,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildSeriesLabel() {
    final label =
        widget.seriesLabelOverride ?? 'Série ${widget.entry.index + 1}';

    return SizedBox(
      width: ExerciseCardStyles.seriesLabelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: ExerciseCardStyles.seriesLabelStyle.copyWith(
              color: ExerciseCardStyles.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.stepSubtitle != null && widget.stepSubtitle!.isNotEmpty)
            Text(
              widget.stepSubtitle!,
              overflow: TextOverflow.ellipsis,
              style: ExerciseCardStyles.seriesLabelStyle,
            ),
        ],
      ),
    );
  }

  Widget _buildRowContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildSeriesLabel(),
        const SizedBox(width: ExerciseCardStyles.columnGap),
        if (widget.showTypeColumn) ...[
          Expanded(flex: 2, child: _buildTypeField()),
          const SizedBox(width: ExerciseCardStyles.columnGap),
        ],
        Expanded(child: _buildWeightField()),
        const SizedBox(width: ExerciseCardStyles.columnGap),
        Expanded(child: _buildRepsField()),
        const SizedBox(width: ExerciseCardStyles.columnGap),
        SizedBox(
          width: ExerciseCardStyles.doneColumnWidth,
          child: Center(child: _buildDoneCheckbox()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isClusterMiniSet) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: ExerciseCardStyles.clusterMiniRowDecoration(),
        child: _buildRowContent(),
      );
    }

    final rowPadding = _compact
        ? ExerciseCardStyles.compactRowPaddingV
        : ExerciseCardStyles.rowPaddingV;

    return Container(
      padding: EdgeInsets.symmetric(vertical: rowPadding),
      decoration: BoxDecoration(
        border: widget.isFirstRow
            ? null
            : const Border(
                top: BorderSide(color: ExerciseCardStyles.rowDivider),
              ),
      ),
      child: _buildRowContent(),
    );
  }
}
