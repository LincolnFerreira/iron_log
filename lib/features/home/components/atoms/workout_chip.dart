import 'package:flutter/material.dart';

class WorkoutChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  
  const WorkoutChip({
    super.key,
    required this.label,
    this.backgroundColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: backgroundColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
