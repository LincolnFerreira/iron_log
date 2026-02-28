import 'package:flutter/material.dart';

class GreetingHeader extends StatelessWidget {
  final String name;
  final String date;
  final String? imageUrl;
  final VoidCallback? onAvatarTap;

  const GreetingHeader({
    super.key,
    required this.name,
    required this.date,
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
            Text(
              'Bom treino,\n$name!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              date,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
