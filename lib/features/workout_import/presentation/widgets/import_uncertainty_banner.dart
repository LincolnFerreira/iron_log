import 'package:flutter/material.dart';

class ImportUncertaintyBanner extends StatelessWidget {
  const ImportUncertaintyBanner({
    super.key,
    required this.unmappedFragments,
    required this.parserWarnings,
  });

  final List<String> unmappedFragments;
  final List<String> parserWarnings;

  @override
  Widget build(BuildContext context) {
    if (unmappedFragments.isEmpty && parserWarnings.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incertezas e trechos preservados',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            ...parserWarnings.map(
              (w) => Text('• $w', style: Theme.of(context).textTheme.bodySmall),
            ),
            ...unmappedFragments.map(
              (f) => Text('"$f"', style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
