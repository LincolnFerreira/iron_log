import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';

class GreetingHeader extends StatelessWidget {
  final String name;
  final String? title;
  final String? imageUrl;
  final VoidCallback? onAvatarTap;

  const GreetingHeader({
    super.key,
    required this.name,
    this.title,
    this.imageUrl,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              const SizedBox(height: 4),
              Text(
                title!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onAvatarTap,
          child: CircleAvatar(
            foregroundImage: NetworkImage(
              imageUrl ?? 'https://placehold.co/150',
            ),
            radius: 30,
          ),
        ),
      ],
    );
  }
}
