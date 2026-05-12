import 'package:flutter/material.dart';

/// Proporção oficial do `app_logo.svg` (viewBox).
const double kAppLogoAspectRatio = 3072 / 2048;

class AppLogo extends StatelessWidget {
  /// Largura máxima desejada; a altura segue [kAppLogoAspectRatio] (sem forçar quadrado).
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const AppLogo({
    super.key,
    this.width = 120,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(8),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final h = width / kAppLogoAspectRatio;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius * 0.7),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: width,
          height: h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
