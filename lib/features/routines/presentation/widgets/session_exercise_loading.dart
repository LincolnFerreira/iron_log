import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/features/home/presentation/components/atoms/workout_loading_card.dart';

/// Skeleton horizontal para os chips de filtro por músculo.
class ExerciseFilterChipsSkeleton extends StatelessWidget {
  const ExerciseFilterChipsSkeleton({super.key});

  static const _chipWidths = [72.0, 88.0, 64.0, 96.0, 80.0];

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);

    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            for (final width in _chipWidths) ...[
              Skeleton(
                child: Container(
                  width: width,
                  height: 32,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton para a lista de exercícios na tela de nova sessão.
class ExerciseListLoadingSkeleton extends StatelessWidget {
  final String? message;
  final int itemCount;

  const ExerciseListLoadingSkeleton({
    super.key,
    this.message,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryLight.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        ...List.generate(itemCount, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 8),
            child: const Skeleton(child: _ExerciseCardSkeleton()),
          );
        }),
      ],
    );
  }
}

class _ExerciseCardSkeleton extends StatelessWidget {
  const _ExerciseCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1E2A42),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: base,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
