import 'package:flutter/material.dart';

class QuickFillChips extends StatelessWidget {
  /// The base weight to apply deltas to (suggestedWeight from AI).
  final double baseWeight;

  /// Called with the absolute weight value when a chip is tapped.
  final void Function(double weight) onWeightSelected;

  const QuickFillChips({
    super.key,
    required this.baseWeight,
    required this.onWeightSelected,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      _ChipConfig(
        label: '−2,5',
        weight: (baseWeight - 2.5).clamp(0.0, double.infinity),
        borderColor: Colors.red.shade400,
        backgroundColor: Colors.red.shade50,
        textColor: Colors.red.shade700,
      ),
      _ChipConfig(
        label: '=',
        weight: baseWeight,
        borderColor: Colors.green.shade500,
        backgroundColor: Colors.green.shade50,
        textColor: Colors.green.shade800,
      ),
      _ChipConfig(
        label: '+2,5',
        weight: baseWeight + 2.5,
        borderColor: Colors.amber.shade600,
        backgroundColor: Colors.amber.shade50,
        textColor: Colors.amber.shade900,
      ),
      _ChipConfig(
        label: '+5',
        weight: baseWeight + 5.0,
        borderColor: Colors.amber.shade600,
        backgroundColor: Colors.amber.shade50,
        textColor: Colors.amber.shade900,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: chips.map((chip) => _buildSingleChip(chip)).toList(),
    );
  }

  Widget _buildSingleChip(_ChipConfig chip) {
    return GestureDetector(
      onTap: () => onWeightSelected(chip.weight),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: chip.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chip.borderColor, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              chip.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: chip.textColor,
              ),
            ),
            Text(
              '${_formatWeight(chip.weight)}kg',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: chip.textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWeight(double weight) {
    if (weight % 1 == 0) return weight.toInt().toString();
    return weight.toStringAsFixed(1);
  }
}

class _ChipConfig {
  final String label;
  final double weight;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  const _ChipConfig({
    required this.label,
    required this.weight,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
  });
}
