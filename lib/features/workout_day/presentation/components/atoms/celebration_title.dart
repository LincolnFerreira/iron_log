import 'package:flutter/material.dart';

/// Título de celebração em fonte grande e peso máximo
class CelebrationTitle extends StatelessWidget {
  final String text;
  final bool animated;

  const CelebrationTitle({super.key, required this.text, this.animated = true});

  @override
  Widget build(BuildContext context) {
    final title = Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    );

    if (!animated) {
      return title;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: AlwaysStoppedAnimation(opacity),
                    curve: Curves.easeOut,
                  ),
                ),
            child: child,
          ),
        );
      },
      child: title,
    );
  }
}
