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
  final bool showDoneColumn;

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
    this.showDoneColumn = true,
  });

  @override
  State<SeriesInputRow> createState() => _SeriesInputRowState();
}

class _SeriesInputRowState extends State<SeriesInputRow> {
  late TextEditingController _weightController;
  late TextEditingController _repController;
  late FocusNode _weightFocusNode;
  late FocusNode _repFocusNode;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _repController = TextEditingController();
    _weightFocusNode = FocusNode();
    _repFocusNode = FocusNode();
    _syncControllersFromEntry();
    widget.activateWeightToken?.addListener(_onActivateWeight);
  }

  @override
  void didUpdateWidget(covariant SeriesInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activateWeightToken != widget.activateWeightToken) {
      oldWidget.activateWeightToken?.removeListener(_onActivateWeight);
      widget.activateWeightToken?.addListener(_onActivateWeight);
    }
    if (oldWidget.entry != widget.entry) {
      if (!_weightFocusNode.hasFocus) {
        _syncWeightControllerFromEntry();
      }
      if (!_repFocusNode.hasFocus) {
        _syncRepsControllerFromEntry();
      }
    }
  }

  @override
  void dispose() {
    widget.activateWeightToken?.removeListener(_onActivateWeight);
    _weightFocusNode.dispose();
    _repFocusNode.dispose();
    _weightController.dispose();
    _repController.dispose();
    super.dispose();
  }

  void _onActivateWeight() {
    widget.onInteract?.call();
    _weightFocusNode.requestFocus();
  }

  void _syncControllersFromEntry() {
    _syncWeightControllerFromEntry();
    _syncRepsControllerFromEntry();
  }

  void _syncWeightControllerFromEntry() {
    _weightController.text = _editableValue(widget.entry.weight);
  }

  void _syncRepsControllerFromEntry() {
    _repController.text = _editableValue(widget.entry.reps);
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
    _repFocusNode.requestFocus();
  }

  void _handleRepsChanged(String val) {
    if (val.isEmpty) return;
    _updateEntry(widget.entry.copyWith(reps: _cleanValue(val)));
  }

  void _handleRepsSubmitted(String val) {
    final reps = val.isEmpty ? widget.entry.reps : _cleanValue(val);
    _updateEntry(widget.entry.copyWith(reps: reps));
    _repFocusNode.unfocus();
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

  String _editableValue(String value) {
    final displayed = _displayValue(value);
    return displayed == '-' ? '' : displayed;
  }

  bool get _compact => widget.visualStyle == SeriesVisualStyle.compactExecution;

  double get _fieldHeight => _compact
      ? ExerciseCardStyles.compactFieldHeight
      : ExerciseCardStyles.fieldHeight;

  static const _typeLabels = <int, String>{
    0: 'Aquec.',
    1: 'Prep.',
    2: 'Trab',
    3: 'Falha',
  };

  Widget _buildInsetField({
    Key? fieldKey,
    required FocusNode focusNode,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSubmitted,
    required String hintText,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final textStyle = ExerciseCardStyles.fieldTextStyleOf(
          context,
          compact: _compact,
        );

        return SizedBox(
          height: _fieldHeight,
          child: Container(
            alignment: Alignment.center,
            decoration: ExerciseCardStyles.fieldBoxDecoration(
              context: context,
              compact: _compact,
              focused: focused,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: fieldKey,
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    inputFormatters: inputFormatters,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: textStyle,
                    onTap: widget.onInteract,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    decoration: ExerciseCardStyles.inlineFieldDecoration(
                      context,
                      hintText: hintText,
                      compact: _compact,
                    ),
                  ),
                ),
                if (suffix != null)
                  Padding(
                    padding: EdgeInsets.only(right: _compact ? 4 : 8),
                    child: suffix,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeField() {
    final itemStyle = ExerciseCardStyles.fieldTextStyleOf(
      context,
      compact: _compact,
    );
    final muted = ExerciseCardStyles.resolvedLabelMuted(context);
    final radius = _compact
        ? ExerciseCardStyles.compactFieldRadius
        : ExerciseCardStyles.fieldRadius;
    final iconSize = _compact ? 16.0 : 18.0;

    return SizedBox(
      height: _fieldHeight,
      child: Container(
        alignment: Alignment.center,
        decoration: ExerciseCardStyles.fieldBoxDecoration(
          context: context,
          compact: _compact,
        ),
        padding: EdgeInsets.only(
          left: _compact ? 4 : 6,
          right: _compact ? 2 : 4,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: widget.entry.type,
            isExpanded: true,
            isDense: true,
            borderRadius: BorderRadius.circular(radius),
            menuMaxHeight: 240,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: iconSize,
              color: muted,
            ),
            iconSize: iconSize,
            style: itemStyle,
            dropdownColor: ExerciseCardStyles.resolvedDropdownMenu(context),
            items: _typeLabels.entries
                .map(
                  (e) => DropdownMenuItem<int>(
                    value: e.key,
                    child: Text(e.value, style: itemStyle),
                  ),
                )
                .toList(),
            selectedItemBuilder: (context) {
              return _typeLabels.values
                  .map(
                    (label) => Align(
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: itemStyle,
                      ),
                    ),
                  )
                  .toList();
            },
            onChanged: _handleTypeChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildWeightField() {
    final fieldKey = widget.seriesKeyIndex != null
        ? WorkoutTestKeys.seriesWeight(widget.seriesKeyIndex!)
        : null;

    return _buildInsetField(
      fieldKey: fieldKey,
      focusNode: _weightFocusNode,
      controller: _weightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onChanged: _handleWeightChanged,
      onSubmitted: _handleWeightSubmitted,
      hintText: '-',
      suffix: Text(
        widget.weightUnit.label,
        style: ExerciseCardStyles.unitHintStyleOf(context, compact: _compact),
      ),
    );
  }

  Widget _buildRepsField() {
    final fieldKey = widget.seriesKeyIndex != null
        ? WorkoutTestKeys.seriesReps(widget.seriesKeyIndex!)
        : null;

    return _buildInsetField(
      fieldKey: fieldKey,
      focusNode: _repFocusNode,
      controller: _repController,
      keyboardType: TextInputType.number,
      textInputAction:
          widget.isLastRow ? TextInputAction.done : TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: _handleRepsChanged,
      onSubmitted: _handleRepsSubmitted,
      hintText: '-',
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
    final muted = ExerciseCardStyles.resolvedLabelMuted(context);
    final primary = ExerciseCardStyles.resolvedTextPrimary(context);

    return SizedBox(
      width: ExerciseCardStyles.seriesLabelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: ExerciseCardStyles.seriesLabelStyle.copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.stepSubtitle != null && widget.stepSubtitle!.isNotEmpty)
            Text(
              widget.stepSubtitle!,
              overflow: TextOverflow.ellipsis,
              style: ExerciseCardStyles.seriesLabelStyle.copyWith(color: muted),
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
          Expanded(
            flex: ExerciseCardStyles.typeColumnFlex,
            child: _buildTypeField(),
          ),
          const SizedBox(width: ExerciseCardStyles.columnGap),
        ],
        Expanded(
          flex: ExerciseCardStyles.weightColumnFlex,
          child: _buildWeightField(),
        ),
        const SizedBox(width: ExerciseCardStyles.columnGap),
        Expanded(
          flex: ExerciseCardStyles.repsColumnFlex,
          child: _buildRepsField(),
        ),
        if (widget.showDoneColumn) ...[
          const SizedBox(width: ExerciseCardStyles.columnGap),
          SizedBox(
            width: ExerciseCardStyles.doneColumnWidth,
            child: Center(child: _buildDoneCheckbox()),
          ),
        ],
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
            : Border(
                top: BorderSide(
                  color: ExerciseCardStyles.resolvedRowDivider(context),
                ),
              ),
      ),
      child: _buildRowContent(),
    );
  }
}
