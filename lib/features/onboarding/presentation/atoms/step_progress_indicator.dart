import 'package:flutter/material.dart';

class StepProgressIndicator extends StatelessWidget {
  final int step;
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = step / totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          borderRadius: BorderRadius.circular(8),
          value: progress,
          backgroundColor: Colors.grey[300],
          color: Theme.of(context).primaryColor,
          minHeight: 8,
        ),
        Text(
          'Passo $step de $totalSteps',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black, fontSize: 14),
        ),
      ],
    );
  }
}
