import 'package:flutter/material.dart';

/// Título padrão para AppBar com label fixo (title) e nome dinâmico (subtitle).
/// Uso: `title: PageHeaderTitle(title: 'Rotina', subtitle: routine.name)`
class PageHeaderTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeaderTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          subtitle.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
