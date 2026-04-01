import 'package:flutter/material.dart';

/// Ícone de status de uma série - apenas leitura
/// Estados: ✓ verde (completada), ⏸ laranja (marcada pra depois), — cinza (não registrada)
class StatusIcon extends StatelessWidget {
  final String status; // 'completed', 'marked_for_later', 'not_registered'
  final double size;
  final bool animated;

  const StatusIcon({
    super.key,
    required this.status,
    this.size = 24.0,
    this.animated = true,
  });

  /// Retorna a cor baseado no status
  Color get _color {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'marked_for_later':
        return const Color(0xFFFFA500); // Orange
      default:
        return const Color(0xFFBDBDBD); // Gray
    }
  }

  /// Retorna o ícone baseado no status
  IconData get _icon {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'marked_for_later':
        return Icons.pause_circle_rounded;
      default:
        return Icons.remove_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(_icon, size: size, color: _color);

    if (!animated) {
      return icon;
    }

    return ScaleTransition(
      scale: Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(
          parent: AlwaysStoppedAnimation(1.0),
          curve: Curves.elasticOut,
        ),
      ),
      child: icon,
    );
  }
}
