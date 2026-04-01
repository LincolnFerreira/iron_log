import 'package:flutter/material.dart';

/// Valor de uma estatística - número grande, bold e colorido
class StatValue extends StatelessWidget {
  final String value;
  final Color color; // Cor semântica: amarelo, verde, roxo, vermelho
  final bool animated;

  const StatValue({
    super.key,
    required this.value,
    required this.color,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color),
    );

    if (!animated) {
      return valueWidget;
    }

    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
          parent: AlwaysStoppedAnimation(1.0),
          curve: Curves.elasticOut,
        ),
      ),
      child: valueWidget,
    );
  }
}
