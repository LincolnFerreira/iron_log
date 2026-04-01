import 'package:flutter/material.dart';

/// Subtítulo contextual - nome da rotina + data curta
/// Formato: "Peito & Tríceps · Ter, 28 Fev"
class ContextualSubtitle extends StatelessWidget {
  final String routineName;
  final String dateFormatted;
  final bool animated;

  const ContextualSubtitle({
    super.key,
    required this.routineName,
    required this.dateFormatted,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = Text(
      '$routineName · $dateFormatted',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: Colors.white70,
        fontWeight: FontWeight.w700,
      ),
    );

    if (!animated) {
      return subtitle;
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: AlwaysStoppedAnimation(1.0),
          curve: Curves.easeOut,
        ),
      ),
      child: subtitle,
    );
  }
}
