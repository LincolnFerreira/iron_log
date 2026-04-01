import 'package:flutter/material.dart';

/// Ícone de troféu - elemento visual isolado e impactante no topo da tela
class TrophyIcon extends StatelessWidget {
  final double size;
  final bool animated;

  const TrophyIcon({super.key, this.size = 120.0, this.animated = true});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.emoji_events_rounded,
      size: 80,
      color: const Color(0xFFFFD700), // Gold
    );

    if (!animated) {
      return icon;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: icon,
    );
  }
}
