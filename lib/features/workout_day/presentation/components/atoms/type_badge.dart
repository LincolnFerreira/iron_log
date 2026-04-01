import 'package:flutter/material.dart';

/// Badge que identifica o tipo de série com cor semântica
/// Tipos: 'warmup' (laranja), 'prep' (roxo), 'work' (verde), 'failure' (vermelho)
class TypeBadge extends StatelessWidget {
  final String type;
  final bool animated;

  const TypeBadge({super.key, required this.type, this.animated = true});

  /// Retorna as configurações de cor e label baseado no tipo
  _TypeConfig get _config {
    switch (type.toLowerCase()) {
      case 'warmup':
        return _TypeConfig(
          color: const Color(0xFFFFA500), // Orange
          label: 'AQUECIMENTO',
        );
      case 'prep':
        return _TypeConfig(
          color: const Color(0xFF9C27B0), // Purple
          label: 'PREPARATÓRIA',
        );
      case 'work':
        return _TypeConfig(
          color: const Color(0xFF4CAF50), // Green
          label: 'TRABALHO',
        );
      case 'failure':
        return _TypeConfig(
          color: const Color(0xFFF44336), // Red
          label: 'FALHA',
        );
      default:
        return _TypeConfig(color: const Color(0xFFFFA500), label: 'OUTRO');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.2),
        border: Border.all(color: config.color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        config.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: config.color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );

    if (!animated) {
      return badge;
    }

    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: AlwaysStoppedAnimation(1.0),
          curve: Curves.easeOut,
        ),
      ),
      child: badge,
    );
  }
}

class _TypeConfig {
  final Color color;
  final String label;

  _TypeConfig({required this.color, required this.label});
}
