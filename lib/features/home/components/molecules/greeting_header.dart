import 'package:flutter/material.dart';

class GreetingHeader extends StatelessWidget {
  final String name;
  final String date;
  final String? imageUrl;

  const GreetingHeader({
    super.key,
    required this.name,
    required this.date,
    this.imageUrl,
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
        CircleAvatar(
          foregroundImage: NetworkImage(
            imageUrl ?? 'https://via.placeholder.com/150',
          ),
          radius: 30,
        ),
      ],
    );
  }
}
