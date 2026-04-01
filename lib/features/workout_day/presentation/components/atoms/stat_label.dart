import 'package:flutter/material.dart';

/// Label de uma estatística - pequeno, uppercase, espaçado
class StatLabel extends StatelessWidget {
  final String label;
  final bool animated;

  const StatLabel({super.key, required this.label, this.animated = true});

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label.toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );

    if (!animated) {
      return labelWidget;
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: AlwaysStoppedAnimation(1.0),
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: labelWidget,
    );
  }
}
