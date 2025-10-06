import 'package:flutter/material.dart';

/// Atom: Add icon with customizable styling
class AddIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool withBackground;
  final Color? backgroundColor;

  const AddIcon({
    super.key,
    this.size = 24,
    this.color,
    this.withBackground = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    Widget iconWidget = Icon(Icons.add, size: size, color: effectiveColor);

    if (withBackground) {
      final effectiveBackgroundColor =
          backgroundColor ?? effectiveColor.withOpacity(0.1);

      iconWidget = Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}
