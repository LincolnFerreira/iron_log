import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iron_log/core/app_colors.dart';

/// Displays the current active streak with fire icon and counter
/// Shows "Sequência Ativa!" with flame icon on left and streak number on right
class ActiveSequenceCard extends StatelessWidget {
  final int streak;

  const ActiveSequenceCard({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Fire icon + label (SVG)
          Row(
            children: [
              SvgPicture.asset(
                'assets/fire-sequence.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sequência Ativa!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  Text(
                    'Não quebre agora',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryLight.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Streak counter
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$streak dias',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
