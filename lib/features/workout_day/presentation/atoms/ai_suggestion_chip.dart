import 'package:flutter/material.dart';
import '../exercise_card_styles.dart';

class AiSuggestionChip extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const AiSuggestionChip({super.key, this.isLoading = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ExerciseCardStyles.accentChipBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ExerciseCardStyles.accent,
                  ),
                ),
              )
            : const Text(
                '✦ IA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ExerciseCardStyles.accent,
                ),
              ),
      ),
    );
  }
}
