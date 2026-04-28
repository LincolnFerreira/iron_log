import 'package:flutter/material.dart';
import 'package:iron_log/features/home/components/atoms/workout_loading_card.dart';

/// Skeleton version of [WorkoutHistoryCard].
class WorkoutHistorySkeletonCard extends StatelessWidget {
  const WorkoutHistorySkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional PR badge placeholder
          Container(
            width: 140,
            height: 18,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 8),

          // Top row: icon + title + date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 160,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Exercise chips placeholder
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              4,
              (_) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const SizedBox(width: 48, height: 10),
              ),
            ),
          ),

          const SizedBox(height: 12),
          // Mini stats row
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 14,
                      width: 36,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 48,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Wrapper that applies animated shimmer from `Skeleton`.
class WorkoutHistorySkeleton extends StatelessWidget {
  const WorkoutHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeleton(child: WorkoutHistorySkeletonCard());
  }
}
