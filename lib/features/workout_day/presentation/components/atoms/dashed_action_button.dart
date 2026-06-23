import 'package:flutter/material.dart';
import '../../exercise_card_styles.dart';

/// Botão de ação secundária com borda tracejada (ex.: Adicionar série).
class DashedActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const DashedActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(ExerciseCardStyles.fieldRadius),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: ExerciseCardStyles.accentBorder,
            borderRadius: ExerciseCardStyles.fieldRadius,
          ),
          child: Container(
            width: double.infinity,
            height: ExerciseCardStyles.fieldHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ExerciseCardStyles.accentBg,
              borderRadius: BorderRadius.circular(
                ExerciseCardStyles.fieldRadius,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: ExerciseCardStyles.accent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ExerciseCardStyles.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + 6),
          paint,
        );
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
