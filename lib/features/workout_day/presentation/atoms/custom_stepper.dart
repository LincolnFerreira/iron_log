import 'package:flutter/material.dart';

class CustomStepper extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final double iconSize;

  const CustomStepper({
    super.key,
    required this.value,
    this.minValue = 0,
    this.maxValue = 999,
    required this.onChanged,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > minValue ? () => onChanged(value - 1) : null,
          icon: Icon(Icons.remove, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            value.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        IconButton(
          onPressed: value < maxValue ? () => onChanged(value + 1) : null,
          icon: Icon(Icons.add, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
