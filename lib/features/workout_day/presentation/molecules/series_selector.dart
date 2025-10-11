import 'package:flutter/material.dart';
import '../atoms/custom_chip.dart';

class SeriesSelector extends StatelessWidget {
  final List<SeriesType> seriesTypes;
  final SeriesType? selectedType;
  final ValueChanged<SeriesType> onTypeSelected;

  const SeriesSelector({
    super.key,
    required this.seriesTypes,
    this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: seriesTypes.asMap().entries.map((entry) {
        final index = entry.key;
        final type = entry.value;
        final isLast = index == seriesTypes.length - 1;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 8),
            child: CustomChip(
              text: type.label,
              backgroundColor: type.color,
              textColor: selectedType == type
                  ? Colors.white
                  : type.color.withOpacity(0.8),
              isSelected: selectedType == type,
              onTap: () => onTypeSelected(type),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SeriesType {
  final String label;
  final Color color;

  const SeriesType({required this.label, required this.color});

  static const warmUp = SeriesType(label: 'Warm-up', color: Color(0xFFFF8A65));
  static const feeder = SeriesType(label: 'Feeder', color: Color(0xFF9E9E9E));
  static const topSet = SeriesType(label: 'Top Set', color: Color(0xFF2196F3));
  static const backOff = SeriesType(
    label: 'Back-off',
    color: Color(0xFFE0E0E0),
  );
}
