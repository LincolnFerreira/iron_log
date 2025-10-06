import 'package:flutter/material.dart';

class PrimaryText extends StatelessWidget {
  final String text;
  final bool isTitle;
  final Color? color;

  const PrimaryText(this.text, {this.isTitle = false, super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: isTitle
          ? Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color ?? Theme.of(context).colorScheme.onSurface,
            )
          : Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
    );
  }
}
